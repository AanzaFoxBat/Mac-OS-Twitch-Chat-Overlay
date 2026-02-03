import AppKit

class OverlayWindow: NSWindow {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        configureWindow()
    }

    private func configureWindow() {
        // Window level - floating above normal windows
        level = .floating

        // Behavior - stay on all spaces and work with fullscreen apps
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Transparency
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // Title configuration
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Appearance
        appearance = NSAppearance(named: .darkAqua)

        // Allow window to become key for receiving input
        acceptsMouseMovedEvents = true
    }

    // Allow window to become key window (receive keyboard input)
    override var canBecomeKey: Bool {
        return true
    }

    // Allow window to become main window
    override var canBecomeMain: Bool {
        return true
    }

    // Save frame when window is moved or resized
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag)
        AppSettings.shared.windowFrame = frameRect
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
        AppSettings.shared.windowFrame = frameRect
    }
}
