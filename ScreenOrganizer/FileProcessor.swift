import Foundation

class FileProcessor {
    
    private let ffmpegPath: String
    private let magickPath: String
    private let dateFormatter: DateFormatter
    
    init() {
        let searchPaths = ["/usr/local/bin", "/opt/homebrew/bin", "/usr/bin"]
        
        ffmpegPath = searchPaths.map { "\($0)/ffmpeg" }.first { FileManager.default.fileExists(atPath: $0) } ?? "ffmpeg"
        magickPath = searchPaths.map { "\($0)/magick" }.first { FileManager.default.fileExists(atPath: $0) } ?? "magick"
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        print("Using ffmpeg: \(ffmpegPath)")
        print("Using magick: \(magickPath)")
    }
    
    /// Returns the output directory for a file, creating a date subfolder if needed.
    private func outputDir(for sourceURL: URL, in baseDir: URL) -> URL {
        guard Config.shared.organizeByDate else { return baseDir }
        
        let date: Date
        if let values = try? sourceURL.resourceValues(forKeys: [.creationDateKey]),
           let created = values.creationDate {
            date = created
        } else {
            date = Date()
        }
        
        let dateFolder = baseDir.appendingPathComponent(dateFormatter.string(from: date))
        try? FileManager.default.createDirectory(at: dateFolder, withIntermediateDirectories: true)
        return dateFolder
    }
    
    func processVideoFile(_ fileURL: URL) {
        let dir = outputDir(for: fileURL, in: Config.shared.screenRecordingsFolderURL)
        let baseName = fileURL.deletingPathExtension().lastPathComponent + ".mp4"
        let outputURL = uniqueURL(for: dir.appendingPathComponent(baseName))
        
        print("Compressing video: \(fileURL.lastPathComponent) → \(outputURL.lastPathComponent)")
        
        let args = [
            ffmpegPath, "-y",
            "-i", fileURL.path,
            "-c:v", "libx265",
            "-crf", Config.shared.videoQuality.videoCRF,
            "-preset", "medium",
            "-c:a", "aac",
            "-b:a", "64k",
            outputURL.path
        ]
        
        if runCommand(args) {
            try? FileManager.default.removeItem(at: fileURL)
            print("Done: \(outputURL.lastPathComponent)")
        } else {
            let fallbackURL = uniqueURL(for: dir.appendingPathComponent(fileURL.lastPathComponent))
            try? FileManager.default.moveItem(at: fileURL, to: fallbackURL)
            print("Moved (no compression): \(fileURL.lastPathComponent)")
        }
    }
    
    func processImageFile(_ fileURL: URL) {
        let ext = fileURL.pathExtension.lowercased()
        let convertToJPEG = ext != "jpg" && ext != "jpeg"
        let dir = outputDir(for: fileURL, in: Config.shared.screenshotsFolderURL)
        
        let targetName: String
        if convertToJPEG {
            targetName = fileURL.deletingPathExtension().lastPathComponent + ".jpg"
        } else {
            targetName = fileURL.lastPathComponent
        }
        
        let finalURL = uniqueURL(for: dir.appendingPathComponent(targetName))
        let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent(".\(finalURL.lastPathComponent).tmp")
        
        print("Compressing image: \(fileURL.lastPathComponent) → \(finalURL.lastPathComponent)")
        
        let args = [
            magickPath, fileURL.path,
            "-strip",
            "-quality", Config.shared.imageQuality.jpegQuality,
            tempURL.path
        ]
        
        if runCommand(args) {
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.moveItem(at: tempURL, to: finalURL)
            print("Compressed: \(finalURL.lastPathComponent)")
        } else {
            try? FileManager.default.removeItem(at: tempURL)
            print("Image compression failed: \(fileURL.lastPathComponent)")
        }
    }
    
    private func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }
        
        let dir = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var counter = 1
        var candidate: URL
        repeat {
            candidate = dir.appendingPathComponent("\(base) (\(counter)).\(ext)")
            counter += 1
        } while fm.fileExists(atPath: candidate.path)
        return candidate
    }
    
    private func runCommand(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", arguments.map { "'\($0)'" }.joined(separator: " ")]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        process.standardInput = FileHandle.nullDevice
        process.qualityOfService = .userInitiated
        
        do {
            try process.run()
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                let errPipe = process.standardError as! Pipe
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8) ?? ""
                NSLog("Command failed (exit %d): %@", status, errMsg)
            }
            return status == 0
        } catch {
            NSLog("Command error: %@", "\(error)")
            return false
        }
    }
}
