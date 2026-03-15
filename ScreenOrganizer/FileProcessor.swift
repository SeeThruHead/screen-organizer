import Foundation

class FileProcessor {
    
    private let ffmpegPath: String
    private let magickPath: String
    
    init() {
        // Find tools in common locations
        let searchPaths = ["/usr/local/bin", "/opt/homebrew/bin", "/usr/bin"]
        
        ffmpegPath = searchPaths.map { "\($0)/ffmpeg" }.first { FileManager.default.fileExists(atPath: $0) } ?? "ffmpeg"
        magickPath = searchPaths.map { "\($0)/magick" }.first { FileManager.default.fileExists(atPath: $0) } ?? "magick"
        
        print("Using ffmpeg: \(ffmpegPath)")
        print("Using magick: \(magickPath)")
    }
    
    func processVideoFile(_ fileURL: URL) {
        let outputURL = Config.shared.screenRecordingsFolderURL.appendingPathComponent(fileURL.lastPathComponent)
        
        print("Compressing video: \(fileURL.lastPathComponent)")
        
        let args = [
            ffmpegPath, "-y",
            "-i", fileURL.path,
            "-c:v", "libx264",
            "-crf", Config.shared.videoQuality.videoCRF,
            "-preset", "medium",
            "-c:a", "aac",
            "-b:a", "64k",
            outputURL.path
        ]
        
        if runCommand(args) {
            try? FileManager.default.removeItem(at: fileURL)
            print("Done: \(fileURL.lastPathComponent) → \(Config.shared.screenRecordingsFolder)/")
        } else {
            // Compression failed, just move the file
            try? FileManager.default.moveItem(at: fileURL, to: outputURL)
            print("Moved (no compression): \(fileURL.lastPathComponent)")
        }
    }
    
    func processPNGFile(_ fileURL: URL) {
        print("Compressing PNG: \(fileURL.lastPathComponent)")
        
        let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent(".\(fileURL.lastPathComponent).tmp")
        
        let args = [
            magickPath, fileURL.path,
            "-strip",
            "-quality", Config.shared.imageQuality.pngQuality,
            "-define", "png:compression-level=9",
            tempURL.path
        ]
        
        if runCommand(args) {
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.moveItem(at: tempURL, to: fileURL)
            print("Compressed: \(fileURL.lastPathComponent)")
        } else {
            try? FileManager.default.removeItem(at: tempURL)
            print("PNG compression failed: \(fileURL.lastPathComponent)")
        }
    }
    
    private func runCommand(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", arguments.map { "'\($0)'" }.joined(separator: " ")]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        process.standardInput = FileHandle.nullDevice
        
        // Ensure child process runs independently
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
