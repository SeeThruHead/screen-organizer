import Cocoa
import CoreServices

class FileWatcher {
    
    private var stream: FSEventStreamRef?
    private let processor = FileProcessor()
    private let dateOrganizer = DateOrganizer()
    private let onProcessingStart: () -> Void
    private let onProcessingComplete: () -> Void
    private var processedFiles: Set<String> = []
    private var isProcessing = false
    private var cooldown = false
    private var debounceWork: DispatchWorkItem?
    
    init(onProcessingStart: @escaping () -> Void, onProcessingComplete: @escaping () -> Void) {
        self.onProcessingStart = onProcessingStart
        self.onProcessingComplete = onProcessingComplete
        
        try? FileManager.default.createDirectory(at: Config.shared.screenshotsFolderURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: Config.shared.screenRecordingsFolderURL, withIntermediateDirectories: true)
        
        startWatching()
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
            0.5,  // 0.5 second latency — batches rapid changes at the OS level
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )
        
        guard let stream = stream else {
            NSLog("Failed to create FSEventStream")
            return
        }
        
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
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
        guard !isProcessing, !cooldown else { return }
        
        let screenshotsURL = Config.shared.screenshotsFolderURL
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: screenshotsURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }
        
        let movFiles = files.filter {
            $0.pathExtension.lowercased() == "mov" && !$0.hasDirectoryPath && !processedFiles.contains($0.lastPathComponent)
        }
        let pngFiles = files.filter {
            $0.pathExtension.lowercased() == "png" && !$0.hasDirectoryPath && !processedFiles.contains($0.lastPathComponent)
        }
        
        guard !movFiles.isEmpty || !pngFiles.isEmpty else { return }
        
        isProcessing = true
        onProcessingStart()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            let concurrent = DispatchQueue(label: "com.screenorganizer.process", attributes: .concurrent)
            
            for file in movFiles {
                group.enter()
                concurrent.async {
                    self.processor.processVideoFile(file)
                    DispatchQueue.main.async { self.processedFiles.insert(file.lastPathComponent) }
                    group.leave()
                }
            }
            for file in pngFiles {
                group.enter()
                concurrent.async {
                    self.processor.processPNGFile(file)
                    DispatchQueue.main.async { self.processedFiles.insert(file.lastPathComponent) }
                    group.leave()
                }
            }
            
            group.wait()
            
            if Config.shared.organizeByDate {
                self.dateOrganizer.organizeFilesByDate()
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.cooldown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.cooldown = false
                }
                self.onProcessingComplete()
            }
        }
    }
    
    func stop() {
        debounceWork?.cancel()
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
