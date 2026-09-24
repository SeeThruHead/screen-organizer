import Cocoa

/// Puts a processed capture on the general pasteboard as one item with several
/// representations, so a single paste does the right thing everywhere: Slack and
/// Finder take the file URL and paste the file, terminals and Claude take the plain
/// text path, and image fields take the PNG data.
enum Clipboard {

    static func copyIfEnabled(_ fileURL: URL) {
        guard Config.shared.copyToClipboard else { return }
        copy(fileURL)
    }

    static func copy(_ fileURL: URL) {
        let item = NSPasteboardItem()
        item.setString(fileURL.absoluteString, forType: .fileURL)
        item.setString(fileURL.path, forType: .string)

        if SupportedFormats.image.contains(fileURL.pathExtension.lowercased()),
           let image = NSImage(contentsOf: fileURL),
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            item.setData(png, forType: .png)
        }

        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            if pasteboard.writeObjects([item]) {
                print("Copied to clipboard: \(fileURL.lastPathComponent)")
            } else {
                NSLog("Failed to copy %@ to the clipboard", fileURL.lastPathComponent)
            }
        }
    }
}
