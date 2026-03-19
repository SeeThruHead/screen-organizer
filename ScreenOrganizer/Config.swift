import Foundation

struct Config {
    
    let screenshotsFolder: String
    let screenRecordingsFolder: String
    let videoQuality: QualityLevel
    let imageQuality: QualityLevel
    let organizeByDate: Bool
    let videoCodec: VideoCodec
    
    init(screenshotsFolder: String, screenRecordingsFolder: String,
         videoQuality: QualityLevel, imageQuality: QualityLevel,
         organizeByDate: Bool, videoCodec: VideoCodec = .h264) {
        self.screenshotsFolder = screenshotsFolder
        self.screenRecordingsFolder = screenRecordingsFolder
        self.videoQuality = videoQuality
        self.imageQuality = imageQuality
        self.organizeByDate = organizeByDate
        self.videoCodec = videoCodec
    }
    
    enum VideoCodec: String, CaseIterable {
        case h264 = "h264"
        case h265 = "h265"
        
        var ffmpegLib: String {
            switch self {
            case .h264: return "libx264"
            case .h265: return "libx265"
            }
        }
    }
    
    enum QualityLevel: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var videoCRF: String {
            switch self {
            case .high: return "22"
            case .medium: return "26"
            case .low: return "32"
            }
        }
        
        var jpegQuality: String {
            switch self {
            case .high: return "95"
            case .medium: return "90"
            case .low: return "80"
            }
        }
    }
    
    static var shared = Config()
    
    static func reload() {
        shared = Config()
    }
    
    private init() {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/screenorganizer")
        
        if let configData = try? Data(contentsOf: configPath),
           let configString = String(data: configData, encoding: .utf8) {
            let parsed = Config.parse(configString)
            self.screenshotsFolder = parsed.screenshotsFolder
            self.screenRecordingsFolder = parsed.screenRecordingsFolder
            self.videoQuality = parsed.videoQuality
            self.imageQuality = parsed.imageQuality
            self.organizeByDate = parsed.organizeByDate
            self.videoCodec = parsed.videoCodec
        } else {
            self.screenshotsFolder = "screenshots"
            self.screenRecordingsFolder = "screen-recordings"
            self.videoQuality = .medium
            self.imageQuality = .medium
            self.organizeByDate = false
            self.videoCodec = .h264
            Config.createDefaultConfig(at: configPath)
        }
    }
    
    private static func parse(_ configString: String) -> Config {
        var screenshotsFolder = "screenshots"
        var screenRecordingsFolder = "screen-recordings"
        var videoQuality = QualityLevel.medium
        var imageQuality = QualityLevel.medium
        var organizeByDate = false
        var videoCodec = VideoCodec.h264
        
        for line in configString.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "screenshotsFolder": screenshotsFolder = value
            case "screenRecordingsFolder": screenRecordingsFolder = value
            case "videoQuality": videoQuality = QualityLevel(rawValue: value) ?? .medium
            case "imageQuality": imageQuality = QualityLevel(rawValue: value) ?? .medium
            case "organizeByDate": organizeByDate = value == "true"
            case "videoCodec": videoCodec = VideoCodec(rawValue: value) ?? .h264
            default: break
            }
        }
        
        return Config(screenshotsFolder: screenshotsFolder, screenRecordingsFolder: screenRecordingsFolder,
                      videoQuality: videoQuality, imageQuality: imageQuality,
                      organizeByDate: organizeByDate, videoCodec: videoCodec)
    }
    
    private static func createDefaultConfig(at url: URL) {
        let content = """
# Screen Organizer Configuration
screenshotsFolder=screenshots
screenRecordingsFolder=screen-recordings

# Quality: low, medium, high
videoQuality=medium
imageQuality=medium

# Video codec: h264 (plays natively on macOS), h265 (smaller files, needs VLC)
videoCodec=h264

# Auto-organize files into YYYY-MM-DD subfolders
organizeByDate=false
"""
        let configDir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    var screenshotsFolderURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(screenshotsFolder)
    }
    
    var screenRecordingsFolderURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(screenRecordingsFolder)
    }
}
