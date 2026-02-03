import AppKit

class StatusBarMenu {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    private let toggleOverlayAction: () -> Void
    private let toggleClickThroughAction: () -> Void
    private let openSettingsAction: () -> Void
    private let quitAction: () -> Void

    private var showHideMenuItem: NSMenuItem?
    private var clickThroughMenuItem: NSMenuItem?

    init(
        toggleOverlayAction: @escaping () -> Void,
        toggleClickThroughAction: @escaping () -> Void,
        openSettingsAction: @escaping () -> Void,
        quitAction: @escaping () -> Void
    ) {
        self.toggleOverlayAction = toggleOverlayAction
        self.toggleClickThroughAction = toggleClickThroughAction
        self.openSettingsAction = openSettingsAction
        self.quitAction = quitAction

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "Overlay")
            button.image?.isTemplate = true
        }

        buildMenu()
        statusItem?.menu = menu
    }

    private func buildMenu() {
        menu = NSMenu()

        // Show/Hide Overlay
        showHideMenuItem = NSMenuItem(title: "Hide Overlay", action: #selector(toggleOverlayPressed), keyEquivalent: "")
        showHideMenuItem?.target = self
        menu?.addItem(showHideMenuItem!)

        // Toggle Click-through
        clickThroughMenuItem = NSMenuItem(title: "Enable Click-through", action: #selector(toggleClickThroughPressed), keyEquivalent: "")
        clickThroughMenuItem?.target = self
        menu?.addItem(clickThroughMenuItem!)

        menu?.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsPressed), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)

        menu?.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Overlay", action: #selector(quitPressed), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }

    func updateMenu() {
        // Update Show/Hide based on window visibility
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
           let window = appDelegate.overlayWindow {
            showHideMenuItem?.title = window.isVisible ? "Hide Overlay" : "Show Overlay"
        }

        // Update Click-through based on settings
        let isClickThroughEnabled = AppSettings.shared.clickThroughEnabled
        clickThroughMenuItem?.title = isClickThroughEnabled ? "Disable Click-through" : "Enable Click-through"
        clickThroughMenuItem?.state = isClickThroughEnabled ? .on : .off
    }

    @objc private func toggleOverlayPressed() {
        toggleOverlayAction()
    }

    @objc private func toggleClickThroughPressed() {
        toggleClickThroughAction()
    }

    @objc private func openSettingsPressed() {
        openSettingsAction()
    }

    @objc private func quitPressed() {
        quitAction()
    }
}
