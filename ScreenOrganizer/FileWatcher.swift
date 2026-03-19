import Cocoa
import CoreServices

class FileWatcher {
    
    static let processedSuffix = "_opt"
    
    private var stream: FSEventStreamRef?
    private let processor = FileProcessor()
    private let dateOrganizer = DateOrganizer()
    private let onProcessingStart: () -> Void
    private let onProcessingComplete: () -> Void
    private var isProcessing = false
    private var debounceWork: DispatchWorkItem?
    private var pollTimer: Timer?
    
    init(onProcessingStart: @escaping () -> Void, onProcessingComplete: @escaping () -> Void) {
        self.onProcessingStart = onProcessingStart
        self.onProcessingComplete = onProcessingComplete
        
        try? FileManager.default.createDirectory(at: Config.shared.screenshotsFolderURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: Config.shared.screenRecordingsFolderURL, withIntermediateDirectories: true)
        
        startWatching()
        startPolling()
    }
    
    private static func isProcessed(_ url: URL) -> Bool {
        url.deletingPathExtension().lastPathComponent.hasSuffix(processedSuffix)
    }
    
    private func startWatching() {
        let path = Config.shared.screenshotsFolderURL.path as CFString
        let paths = [path] as CFArray
        
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        stream = FSEventStreamCreate(
            nil,
            fsEventCallback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )
        
        guard let stream = stream else {
            NSLog("Failed to create FSEventStream")
            return
        }
        
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
    }
    
    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkForNewFiles()
        }
    }
    
    // Called from the C callback — debounces rapid events
    fileprivate func handleEvent() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.checkForNewFiles()
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }
    
    private func checkForNewFiles() {
        guard !isProcessing else { return }
        
        let screenshotsURL = Config.shared.screenshotsFolderURL
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: screenshotsURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }
        
        let videoFiles = files.filter {
            SupportedFormats.video.contains($0.pathExtension.lowercased())
                && !$0.hasDirectoryPath
                && !FileWatcher.isProcessed($0)
        }
        let imageFiles = files.filter {
            SupportedFormats.image.contains($0.pathExtension.lowercased())
                && !$0.hasDirectoryPath
                && !FileWatcher.isProcessed($0)
        }
        
        guard !videoFiles.isEmpty || !imageFiles.isEmpty else { return }
        
        isProcessing = true
        onProcessingStart()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            let concurrent = DispatchQueue(label: "com.screenorganizer.process", attributes: .concurrent)
            
            // Group videos by output name to detect collisions
            var videoGroups: [String: [URL]] = [:]
            for file in videoFiles {
                let outputName = file.deletingPathExtension().lastPathComponent + ".mp4"
                videoGroups[outputName, default: []].append(file)
            }
            
            // Group images by output name
            var imageGroups: [String: [URL]] = [:]
            for file in imageFiles {
                let ext = file.pathExtension.lowercased()
                let outputName = (ext == "jpg" || ext == "jpeg")
                    ? file.lastPathComponent
                    : file.deletingPathExtension().lastPathComponent + ".jpg"
                imageGroups[outputName, default: []].append(file)
            }
            
            // Each group runs in parallel; files within a colliding group run sequentially
            for (_, files) in videoGroups {
                group.enter()
                concurrent.async {
                    for file in files {
                        self.processor.processVideoFile(file)
                    }
                    group.leave()
                }
            }
            for (_, files) in imageGroups {
                group.enter()
                concurrent.async {
                    for file in files {
                        self.processor.processImageFile(file)
                    }
                    group.leave()
                }
            }
            
            group.wait()
            
            // Sweep any loose files into date folders (e.g. organizeByDate was just turned on)
            if Config.shared.organizeByDate {
                self.dateOrganizer.organizeFilesByDate()
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.onProcessingComplete()
            }
        }
    }
    
    func stop() {
        debounceWork?.cancel()
        pollTimer?.invalidate()
        pollTimer = nil
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
    }
}

private func fsEventCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }
    let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
    watcher.handleEvent()
}
