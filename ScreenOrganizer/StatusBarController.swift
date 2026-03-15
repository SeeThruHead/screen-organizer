import Cocoa

class StatusBarController: NSObject {
    
    private var statusBarItem: NSStatusItem!
    private var fileWatcher: FileWatcher?
    private var organizeByDateItem: NSMenuItem!
    
    override init() {
        super.init()
        setupStatusBar()
        startWatching()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Screen Organizer")
            button.image?.isTemplate = true
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Screen Organizer", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("Open Screenshots Folder", action: #selector(openScreenshotsFolder)))
        menu.addItem(menuItem("Open Recordings Folder", action: #selector(openRecordingsFolder)))
        menu.addItem(NSMenuItem.separator())
        
        organizeByDateItem = menuItem("Organize by Date", action: #selector(toggleOrganizeByDate))
        organizeByDateItem.state = Config.shared.organizeByDate ? .on : .off
        menu.addItem(organizeByDateItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("Settings...", action: #selector(showSettings)))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("Quit", action: #selector(quit), key: "q"))
        
        statusBarItem.menu = menu
    }
    
    private func menuItem(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }
    
    private func startWatching() {
        fileWatcher = FileWatcher(
            onProcessingStart: { [weak self] in self?.setProcessing(true) },
            onProcessingComplete: { [weak self] in self?.setProcessing(false) }
        )
    }
    
    private func setProcessing(_ isProcessing: Bool) {
        DispatchQueue.main.async {
            if let button = self.statusBarItem.button {
                let name = isProcessing ? "gearshape.fill" : "camera"
                button.image = NSImage(systemSymbolName: name, accessibilityDescription: "Screen Organizer")
                button.image?.isTemplate = true
            }
        }
    }
    
    @objc private func openScreenshotsFolder() {
        NSWorkspace.shared.open(Config.shared.screenshotsFolderURL)
    }
    
    @objc private func openRecordingsFolder() {
        NSWorkspace.shared.open(Config.shared.screenRecordingsFolderURL)
    }
    
    @objc private func toggleOrganizeByDate() {
        let newValue = !Config.shared.organizeByDate
        organizeByDateItem.state = newValue ? .on : .off
        saveCurrentConfig(organizeByDate: newValue)
        
        // If just enabled, organize existing files now
        if newValue {
            setProcessing(true)
            DispatchQueue.global(qos: .userInitiated).async {
                DateOrganizer().organizeFilesByDate()
                DispatchQueue.main.async { self.setProcessing(false) }
            }
        }
    }
    
    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        let alert = NSAlert()
        alert.messageText = "Screen Organizer Settings"
        alert.informativeText = "Folders are relative to your home directory"
        
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 160))
        
        let screenshotsLabel = NSTextField(labelWithString: "Screenshots Folder:")
        screenshotsLabel.frame = NSRect(x: 0, y: 130, width: 150, height: 20)
        view.addSubview(screenshotsLabel)
        
        let screenshotsField = NSTextField(frame: NSRect(x: 160, y: 130, width: 190, height: 22))
        screenshotsField.stringValue = Config.shared.screenshotsFolder
        view.addSubview(screenshotsField)
        
        let recordingsLabel = NSTextField(labelWithString: "Recordings Folder:")
        recordingsLabel.frame = NSRect(x: 0, y: 100, width: 150, height: 20)
        view.addSubview(recordingsLabel)
        
        let recordingsField = NSTextField(frame: NSRect(x: 160, y: 100, width: 190, height: 22))
        recordingsField.stringValue = Config.shared.screenRecordingsFolder
        view.addSubview(recordingsField)
        
        let videoLabel = NSTextField(labelWithString: "Video Quality:")
        videoLabel.frame = NSRect(x: 0, y: 65, width: 150, height: 20)
        view.addSubview(videoLabel)
        
        let videoPopup = NSPopUpButton(frame: NSRect(x: 160, y: 63, width: 100, height: 24))
        videoPopup.addItems(withTitles: ["low", "medium", "high"])
        videoPopup.selectItem(withTitle: Config.shared.videoQuality.rawValue)
        view.addSubview(videoPopup)
        
        let imageLabel = NSTextField(labelWithString: "Image Quality:")
        imageLabel.frame = NSRect(x: 0, y: 35, width: 150, height: 20)
        view.addSubview(imageLabel)
        
        let imagePopup = NSPopUpButton(frame: NSRect(x: 160, y: 33, width: 100, height: 24))
        imagePopup.addItems(withTitles: ["low", "medium", "high"])
        imagePopup.selectItem(withTitle: Config.shared.imageQuality.rawValue)
        view.addSubview(imagePopup)
        
        alert.accessoryView = view
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            saveSettings(
                screenshotsFolder: screenshotsField.stringValue,
                recordingsFolder: recordingsField.stringValue,
                videoQuality: videoPopup.selectedItem?.title ?? "medium",
                imageQuality: imagePopup.selectedItem?.title ?? "medium"
            )
        }
    }
    
    private func saveSettings(screenshotsFolder: String, recordingsFolder: String,
                              videoQuality: String, imageQuality: String) {
        writeConfig(screenshotsFolder: screenshotsFolder, recordingsFolder: recordingsFolder,
                    videoQuality: videoQuality, imageQuality: imageQuality,
                    organizeByDate: Config.shared.organizeByDate)
    }
    
    private func saveCurrentConfig(organizeByDate: Bool) {
        writeConfig(screenshotsFolder: Config.shared.screenshotsFolder,
                    recordingsFolder: Config.shared.screenRecordingsFolder,
                    videoQuality: Config.shared.videoQuality.rawValue,
                    imageQuality: Config.shared.imageQuality.rawValue,
                    organizeByDate: organizeByDate)
    }
    
    private func writeConfig(screenshotsFolder: String, recordingsFolder: String,
                             videoQuality: String, imageQuality: String, organizeByDate: Bool) {
        let content = """
# Screen Organizer Configuration
screenshotsFolder=\(screenshotsFolder)
screenRecordingsFolder=\(recordingsFolder)

# Quality: low, medium, high
videoQuality=\(videoQuality)
imageQuality=\(imageQuality)

# Auto-organize files into YYYY-MM-DD subfolders
organizeByDate=\(organizeByDate)
"""
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/screenorganizer")
        
        do {
            try FileManager.default.createDirectory(at: configPath.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try content.write(to: configPath, atomically: true, encoding: .utf8)
            Config.reload()
            restartWatching()
        } catch {
            NSLog("Failed to save config: %@", "\(error)")
        }
    }
    
    private func restartWatching() {
        fileWatcher?.stop()
        fileWatcher = FileWatcher(
            onProcessingStart: { [weak self] in self?.setProcessing(true) },
            onProcessingComplete: { [weak self] in self?.setProcessing(false) }
        )
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func cleanup() {
        fileWatcher?.stop()
    }
}
