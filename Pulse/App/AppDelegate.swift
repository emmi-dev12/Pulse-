import AppKit
import SwiftUI
import AVFoundation
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = RecordingCoordinator()
    let pillViewModel = PillViewModel()
    private var pillWindow: PillWindow?
    private var statusItem: NSStatusItem?
    private let onboardingCoordinator = OnboardingCoordinator()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
        setupMenuBarItem()
        setupPillWindow()
        setupPillBinding()
        coordinator.start()
        onboardingCoordinator.showIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Setup

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(
            systemSymbolName: "waveform.and.mic",
            accessibilityDescription: "Pulse"
        )
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Pulse",  action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Settings…",   action: #selector(showSettings),   keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pulse",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        statusItem?.menu = menu
    }

    private func setupPillWindow() {
        let win = PillWindow(viewModel: pillViewModel)
        win.positionAtBottomCenter()
        win.orderFront(nil)
        pillWindow = win
    }

    private func setupPillBinding() {
        pillViewModel.bind(to: coordinator.audioRecorder)

        coordinator.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                switch state {
                case .recording:
                    self?.pillViewModel.show()
                case .idle, .error:
                    self?.pillViewModel.hide()
                case .transcribing:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu actions

    @objc private func showMainWindow() {
        NSApp.windows.first { !($0 is NSPanel) }?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings() {
        onboardingCoordinator.show()
    }
}
