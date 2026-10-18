import Foundation

/// macOS holds a new screenshot in a floating thumbnail for about five seconds before
/// writing the file, which delays everything Screen Organizer does with it. This reads
/// and flips the same setting as "Show Floating Thumbnail" in the Screenshot app.
enum ScreenshotThumbnail {

    private static let domain = "com.apple.screencapture" as CFString
    private static let key = "show-thumbnail" as CFString

    static var isEnabled: Bool {
        CFPreferencesCopyAppValue(key, domain) as? Bool ?? true
    }

    static func setEnabled(_ enabled: Bool) {
        CFPreferencesSetAppValue(key, enabled as CFBoolean, domain)
        CFPreferencesAppSynchronize(domain)
    }
}
