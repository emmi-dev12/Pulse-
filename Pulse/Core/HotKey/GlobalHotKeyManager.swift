import Cocoa
import Carbon.HIToolbox

final class GlobalHotKeyManager {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRecording = false
    private var accessibilityCheckTimer: Timer?

    func start() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(opts) {
            installTap()
        } else {
            scheduleAccessibilityCheck()
        }
    }

    func stop() {
        accessibilityCheckTimer?.invalidate()
        accessibilityCheckTimer = nil
        removeTap()
    }

    // MARK: - Tap lifecycle

    private func installTap() {
        guard eventTap == nil else { return }

        let mask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue)
        )

        // Pass self through userInfo via Unmanaged so the C callback can reach it.
        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: selfPtr
        ) else {
            // Permission not granted yet; schedule retry
            Unmanaged<GlobalHotKeyManager>.fromOpaque(selfPtr).release()
            scheduleAccessibilityCheck()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
    }

    private func scheduleAccessibilityCheck() {
        accessibilityCheckTimer?.invalidate()
        accessibilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if AXIsProcessTrusted() {
                self.accessibilityCheckTimer?.invalidate()
                self.accessibilityCheckTimer = nil
                self.installTap()
            }
        }
    }

    // MARK: - Key handling (called from C callback)

    fileprivate func handleKeyEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        guard keyCode == kVK_Space, flags.contains(.maskAlternate) else {
            return Unmanaged.passRetained(event)
        }

        switch type {
        case .keyDown:
            guard !isRecording else { return nil }  // suppress key-repeat
            isRecording = true
            DispatchQueue.main.async { self.onKeyDown?() }
            return nil  // suppress — prevent space from reaching text fields

        case .keyUp:
            guard isRecording else { return nil }
            isRecording = false
            DispatchQueue.main.async { self.onKeyUp?() }
            return nil

        default:
            return Unmanaged.passRetained(event)
        }
    }
}

// MARK: - C callback (cannot capture Swift instances directly)

private let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userInfo).takeUnretainedValue()
    return manager.handleKeyEvent(type: type, event: event)
}
