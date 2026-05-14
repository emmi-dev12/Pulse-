import AppKit
import SwiftUI

final class PillWindow: NSPanel {
    private let viewModel: PillViewModel

    init(viewModel: PillViewModel) {
        self.viewModel = viewModel
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
        setContent()
        positionAtBottomCenter()
    }

    private func configure() {
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isReleasedWhenClosed = false
    }

    private func setContent() {
        contentView = NSHostingView(
            rootView: PillView(viewModel: viewModel)
                .environmentObject(viewModel)
        )
    }

    func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let origin = CGPoint(
            x: f.minX + (f.width - 140) / 2,
            y: f.minY + 72
        )
        setFrameOrigin(origin)
    }
}
