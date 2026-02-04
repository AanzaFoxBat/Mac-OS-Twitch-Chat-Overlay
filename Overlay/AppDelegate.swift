import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var overlayWindow: OverlayWindow?
    var overlayViewController: OverlayViewController?
    var statusBarMenu: StatusBarMenu?
    var settingsWindow: NSWindow?
    var hotkeyManager: HotkeyManager?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()
        setupStatusBarMenu()
        setupHotkeyManager()
        setupMainMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveWindowFrame()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Setup

    private func setupOverlayWindow() {
        let settings = AppSettings.shared
        let defaultFrame = NSRect(x: 0, y: 0, width: 400, height: 600)

        let frame: NSRect
        if let savedFrame = settings.windowFrame {
            frame = savedFrame
        } else {
            frame = defaultFrame
        }

        overlayWindow = OverlayWindow(contentRect: frame)
        overlayViewController = OverlayViewController()
        overlayWindow?.contentViewController = overlayViewController

        if settings.isFirstLaunch {
            overlayWindow?.center()
        }

        overlayWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func setupStatusBarMenu() {
        statusBarMenu = StatusBarMenu(
            toggleOverlayAction: { [weak self] in
                self?.toggleOverlay()
            },
            toggleClickThroughAction: { [weak self] in
                self?.toggleClickThrough()
            },
            openSettingsAction: { [weak self] in
                self?.openSettings()
            },
            quitAction: {
                NSApplication.shared.terminate(nil)
            }
        )
    }

    private func setupHotkeyManager() {
        let settings = AppSettings.shared

        hotkeyManager = HotkeyManager(
            toggleAction: { [weak self] in
                self?.toggleClickThrough()
            },
            keyCode: settings.hotkeyKeyCode,
            modifiers: settings.hotkeyModifiers
        )

        // Subscribe to hotkey setting changes
        Publishers.CombineLatest(settings.$hotkeyKeyCode, settings.$hotkeyModifiers)
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keyCode, modifiers in
                self?.hotkeyManager?.updateHotkey(keyCode: keyCode, modifiers: modifiers)
            }
            .store(in: &cancellables)
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Overlay", action: #selector(showAboutPanel), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsFromMenu), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Overlay", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit Menu - explicitly set nil target for responder chain routing
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")

        let undoItem = NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        undoItem.target = nil
        editMenu.addItem(undoItem)

        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.target = nil
        editMenu.addItem(redoItem)

        editMenu.addItem(NSMenuItem.separator())

        let cutItem = NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        cutItem.target = nil
        editMenu.addItem(cutItem)

        let copyItem = NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        copyItem.target = nil
        editMenu.addItem(copyItem)

        let pasteItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        pasteItem.target = nil
        editMenu.addItem(pasteItem)

        editMenu.addItem(NSMenuItem.separator())

        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        selectAllItem.target = nil
        editMenu.addItem(selectAllItem)

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Show Overlay", action: #selector(showOverlayFromMenu), keyEquivalent: ""))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    // MARK: - Actions

    func toggleOverlay() {
        if let window = overlayWindow {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }
        statusBarMenu?.updateMenu()
    }

    func toggleClickThrough() {
        let settings = AppSettings.shared
        settings.clickThroughEnabled.toggle()

        overlayWindow?.ignoresMouseEvents = settings.clickThroughEnabled
        statusBarMenu?.updateMenu()
    }

    func openSettings() {
        // Always create a fresh settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 400, height: 560))
        window.minSize = NSSize(width: 400, height: 170)
        window.maxSize = NSSize(width: 400, height: 750)
        window.delegate = self
        window.center()
        settingsWindow = window

        // Temporarily lower overlay so settings can receive input
        overlayWindow?.level = .normal
        NSApplication.shared.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showAboutPanel() {
        let credits = NSMutableAttributedString()

        // Description
        let description = NSAttributedString(
            string: "Live Stream Chat Overlay for macOS\n\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        credits.append(description)

        // GitHub link
        let linkText = NSAttributedString(
            string: "GitHub Repository",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .link: URL(string: "https://github.com/miikkis-gh/Mac-OS-Twitch-Chat-Overlay")!,
                .foregroundColor: NSColor.linkColor
            ]
        )
        credits.append(linkText)

        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .credits: credits
        ])
    }

    @objc private func openSettingsFromMenu() {
        openSettings()
    }

    @objc private func showOverlayFromMenu() {
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    private func saveWindowFrame() {
        if let frame = overlayWindow?.frame {
            AppSettings.shared.windowFrame = frame
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            // Restore overlay to floating level
            overlayWindow?.level = .floating
            // Clear reference so a new window is created next time
            settingsWindow = nil
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard sender == settingsWindow else { return frameSize }

        // Snap points for different sections (measured from actual layout)
        let snapHeights: [CGFloat] = [
            170,  // URL section only
            380,  // + Appearance section
            480,  // + Click-Through section
            560,  // + Window section
            750   // + Advanced Options section (expanded)
        ]

        let snapThreshold: CGFloat = 25

        var newSize = frameSize

        // Find nearest snap point
        for snapHeight in snapHeights {
            if abs(frameSize.height - snapHeight) < snapThreshold {
                newSize.height = snapHeight
                break
            }
        }

        return newSize
    }
}
