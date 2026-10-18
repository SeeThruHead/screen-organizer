import Cocoa
import ImageIO

/// Puts a processed capture on the general pasteboard as one item with several
/// representations, so a single paste does the right thing everywhere: Slack and
/// Finder take the file URL and paste the file, terminals and Claude take the plain
/// text path, and image fields take the image data.
///
/// The URL and path are written immediately. Image data is promised instead of
/// encoded up front: the JPEG bytes are only read, and PNG/TIFF are rendered on
/// demand when an app actually asks for them, so the copy itself is instant.
enum Clipboard {

    private static var activeProvider: ImageDataProvider?

    static func copyIfEnabled(_ fileURL: URL) {
        guard Config.shared.copyToClipboard else { return }
        copy(fileURL)
    }

    static func copy(_ fileURL: URL) {
        DispatchQueue.main.async {
            let item = NSPasteboardItem()
            item.setString(fileURL.absoluteString, forType: .fileURL)
            item.setString(fileURL.path, forType: .string)

            if SupportedFormats.image.contains(fileURL.pathExtension.lowercased()) {
                let provider = ImageDataProvider(fileURL: fileURL)
                activeProvider = provider
                item.setDataProvider(provider, forTypes: [.png, .tiff])
            }

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

/// Renders the image file into the format a paste target requests, only when asked.
final class ImageDataProvider: NSObject, NSPasteboardItemDataProvider {

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        let uti: CFString = type == .tiff ? "public.tiff" as CFString : "public.png" as CFString
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, uti, 1, nil) else { return }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return }
        item.setData(data as Data, forType: type)
    }
}
