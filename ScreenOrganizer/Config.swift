import Foundation

struct Config {
    
    let screenshotsFolder: String
    let screenRecordingsFolder: String
    let videoQuality: QualityLevel
    let imageQuality: QualityLevel
    let organizeByDate: Bool
    
    init(screenshotsFolder: String, screenRecordingsFolder: String,
         videoQuality: QualityLevel, imageQuality: QualityLevel, organizeByDate: Bool) {
        self.screenshotsFolder = screenshotsFolder
        self.screenRecordingsFolder = screenRecordingsFolder
        self.videoQuality = videoQuality
        self.imageQuality = imageQuality
        self.organizeByDate = organizeByDate
    }
    
    enum QualityLevel: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var videoCRF: String {
            switch self {
            case .high: return "20"
            case .medium: return "28"
            case .low: return "35"
            }
        }
        
        var pngQuality: String {
            switch self {
            case .high: return "95"
            case .medium: return "85"
            case .low: return "70"
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
        } else {
            self.screenshotsFolder = "screenshots"
            self.screenRecordingsFolder = "screen-recordings"
            self.videoQuality = .medium
            self.imageQuality = .medium
            self.organizeByDate = false
            Config.createDefaultConfig(at: configPath)
        }
    }
    
    private static func parse(_ configString: String) -> Config {
        var screenshotsFolder = "screenshots"
        var screenRecordingsFolder = "screen-recordings"
        var videoQuality = QualityLevel.medium
        var imageQuality = QualityLevel.medium
        var organizeByDate = false
        
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
            default: break
            }
        }
        
        return Config(screenshotsFolder: screenshotsFolder, screenRecordingsFolder: screenRecordingsFolder,
                      videoQuality: videoQuality, imageQuality: imageQuality, organizeByDate: organizeByDate)
    }
    
    private static func createDefaultConfig(at url: URL) {
        let content = """
# Screen Organizer Configuration
screenshotsFolder=screenshots
screenRecordingsFolder=screen-recordings

# Quality: low, medium, high
videoQuality=medium
imageQuality=medium

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
