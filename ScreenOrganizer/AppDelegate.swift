import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBar: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("App launched")
        statusBar = StatusBarController()
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        statusBar?.cleanup()
        return .terminateNow
    }
}
