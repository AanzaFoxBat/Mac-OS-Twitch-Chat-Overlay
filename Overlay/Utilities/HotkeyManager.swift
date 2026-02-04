import AppKit
import Carbon.HIToolbox

class HotkeyManager {
    private let toggleAction: () -> Void
    private var localMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private static var sharedInstance: HotkeyManager?

    private var currentKeyCode: UInt16
    private var currentModifiers: UInt

    init(toggleAction: @escaping () -> Void, keyCode: UInt16 = UInt16(kVK_ISO_Section), modifiers: UInt = NSEvent.ModifierFlags.control.rawValue) {
        self.toggleAction = toggleAction
        self.currentKeyCode = keyCode
        self.currentModifiers = modifiers
        HotkeyManager.sharedInstance = self
        setupLocalMonitor()
        setupGlobalHotkey()
    }

    deinit {
        removeMonitors()
    }

    func updateHotkey(keyCode: UInt16, modifiers: UInt) {
        // Unregister existing hotkey
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        // Update stored values
        currentKeyCode = keyCode
        currentModifiers = modifiers

        // Register new hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x4F564C59), id: 1) // "OVLY"
        let carbonMods = carbonModifiers(from: NSEvent.ModifierFlags(rawValue: modifiers))

        RegisterEventHotKey(
            UInt32(keyCode),
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func setupLocalMonitor() {
        // Local monitor for when app is in foreground
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isHotkeyPressed(event) == true {
                self?.toggleAction()
                return nil // Consume the event
            }
            return event
        }
    }

    private func setupGlobalHotkey() {
        // Use Carbon API for reliable global hotkey
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install event handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.sharedInstance?.toggleAction()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        // Register hotkey with current key code and modifiers
        let hotKeyID = EventHotKeyID(signature: OSType(0x4F564C59), id: 1) // "OVLY"
        let carbonMods = carbonModifiers(from: NSEvent.ModifierFlags(rawValue: currentModifiers))

        RegisterEventHotKey(
            UInt32(currentKeyCode),
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func removeMonitors() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    private func isHotkeyPressed(_ event: NSEvent) -> Bool {
        // Check for configured hotkey
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let requiredFlags = NSEvent.ModifierFlags(rawValue: currentModifiers).intersection(.deviceIndependentFlagsMask)

        let isCorrectKey = event.keyCode == currentKeyCode
        let hasRequiredModifiers = flags == requiredFlags

        return isCorrectKey && hasRequiredModifiers
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0

        if flags.contains(.control) {
            carbonMods |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            carbonMods |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            carbonMods |= UInt32(shiftKey)
        }
        if flags.contains(.command) {
            carbonMods |= UInt32(cmdKey)
        }

        return carbonMods
    }
}
