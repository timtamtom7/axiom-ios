import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover?
    var statusBarButton: NSStatusBarButton?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)  // Hide dock icon — menu bar app

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusBarButton = item.button
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Axiom")
            button.action = #selector(togglePopover)
            button.target = self
            // Popover only opens on user click, not on launch
        }
    }

    @objc func togglePopover() {
        guard let popover = popover, let button = statusBarButton else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {}
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
