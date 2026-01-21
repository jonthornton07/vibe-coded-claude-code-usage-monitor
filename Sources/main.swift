import Cocoa

// Create the application
let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Run as menu bar app without dock icon

// Set up the app delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        print("Claude Code Monitor started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Claude Code Monitor stopped")
    }
}

let delegate = AppDelegate()
app.delegate = delegate

// Run the app
app.run()
