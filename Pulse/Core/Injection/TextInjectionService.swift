import Cocoa
import ApplicationServices

final class TextInjectionService {
    // Call this at keyDown time, before recording starts.
    // Returns a snapshot of the currently focused AXUIElement.
    func captureFocusedElement() -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system,
                                            kAXFocusedApplicationAttribute as CFString,
                                            &focusedApp) == .success,
              let app = focusedApp
        else { return nil }

        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app as! AXUIElement,
                                            kAXFocusedUIElementAttribute as CFString,
                                            &focusedElement) == .success
        else { return nil }

        return (focusedElement as! AXUIElement)
    }

    func inject(text: String, into element: AXUIElement?) {
        guard let element else {
            pasteboardFallback(text: text)
            return
        }

        // Detect web content (browsers, Electron) and skip straight to fallback
        var roleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        if let role = roleValue as? String, role == "AXWebArea" {
            pasteboardFallback(text: text)
            return
        }

        // Read current value, append new text
        var currentValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &currentValue)
        let existing = (currentValue as? String) ?? ""
        let newValue = existing.isEmpty ? text : existing + " " + text

        let result = AXUIElementSetAttributeValue(element,
                                                  kAXValueAttribute as CFString,
                                                  newValue as CFString)
        if result != .success {
            pasteboardFallback(text: text)
        }
    }

    // MARK: - Fallback via pasteboard + Cmd+V

    private func pasteboardFallback(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        let source = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown   = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp     = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        vDown?.flags   = .maskCommand
        vUp?.flags     = .maskCommand

        let tap: CGEventTapLocation = .cgSessionEventTap
        cmdDown?.post(tap: tap)
        vDown?.post(tap: tap)
        vUp?.post(tap: tap)
        cmdUp?.post(tap: tap)
    }
}
