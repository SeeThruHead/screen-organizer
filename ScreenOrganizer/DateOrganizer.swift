import Foundation

class DateOrganizer {
    
    private let homeURL = FileManager.default.homeDirectoryForCurrentUser
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    func organizeFilesByDate() {
        print("Starting date-based organization...")
        
        organizeFolder(name: Config.shared.screenshotsFolder, fileExtensions: SupportedFormats.image)
        organizeFolder(name: Config.shared.screenRecordingsFolder, fileExtensions: SupportedFormats.video)
        
        print("Date-based organization complete")
    }
    
    private func organizeFolder(name: String, fileExtensions: Set<String>) {
        let folderURL = homeURL.appendingPathComponent(name)
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: folderURL, 
                                                                      includingPropertiesForKeys: [.creationDateKey],
                                                                      options: .skipsHiddenFiles) else {
            print("Could not read \(name) folder")
            return
        }
        
        for file in files {
            // Skip directories and files we're not interested in
            guard !file.hasDirectoryPath,
                  fileExtensions.contains(file.pathExtension.lowercased()) else {
                continue
            }
            
            organizeFile(file, in: folderURL)
        }
    }
    
    private func organizeFile(_ fileURL: URL, in parentFolder: URL) {
        do {
            // Get file creation date
            let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
            guard let creationDate = resourceValues.creationDate else {
                print("Could not get creation date for: \(fileURL.lastPathComponent)")
                return
            }
            
            // Create date string (YYYY-MM-DD)
            let dateString = dateFormatter.string(from: creationDate)
            
            // Create date folder if it doesn't exist
            let dateFolderURL = parentFolder.appendingPathComponent(dateString)
            if !FileManager.default.fileExists(atPath: dateFolderURL.path) {
                try FileManager.default.createDirectory(at: dateFolderURL, 
                                                       withIntermediateDirectories: true)
                print("Created folder: \(dateString)")
            }
            
            // Move file to date folder
            let destinationURL = dateFolderURL.appendingPathComponent(fileURL.lastPathComponent)
            
            // Handle name conflicts
            let finalDestinationURL = getUniqueFileName(for: destinationURL)
            
            try FileManager.default.moveItem(at: fileURL, to: finalDestinationURL)
            print("Moved \(fileURL.lastPathComponent) to \(dateString)/")
            
        } catch {
            print("Error organizing file \(fileURL.lastPathComponent): \(error)")
        }
    }
    
    private func getUniqueFileName(for url: URL) -> URL {
        var counter = 1
        var uniqueURL = url
        
        while FileManager.default.fileExists(atPath: uniqueURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newName = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            uniqueURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        
        return uniqueURL
    }
}