import AppKit
import SwiftUI

final class OnboardingCoordinator {
    private var window: NSWindow?

    func showIfNeeded() {
        let keychain = KeychainService()
        guard !keychain.credentialsComplete else { return }
        show()
    }

    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = ""
        win.titlebarAppearsTransparent = true
        win.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1)
        win.isMovableByWindowBackground = true
        win.center()

        win.contentView = NSHostingView(
            rootView: OnboardingView(onComplete: { [weak self, weak win] in
                win?.close()
                self?.window = nil
                NSApp.windows
                    .first { !($0 is NSPanel) && $0 !== win }?
                    .makeKeyAndOrderFront(nil)
            })
        )
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}
