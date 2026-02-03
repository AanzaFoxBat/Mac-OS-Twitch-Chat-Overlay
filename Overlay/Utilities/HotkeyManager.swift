import AppKit
import Carbon.HIToolbox

class HotkeyManager {
    private let toggleAction: () -> Void
    private var localMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private static var sharedInstance: HotkeyManager?

    init(toggleAction: @escaping () -> Void) {
        self.toggleAction = toggleAction
        HotkeyManager.sharedInstance = self
        setupLocalMonitor()
        setupGlobalHotkey()
    }

    deinit {
        removeMonitors()
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

        // Register Ctrl+§ (key code 10 = kVK_ISO_Section)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4F564C59), id: 1) // "OVLY"
        let modifiers: UInt32 = UInt32(controlKey) // Control key

        RegisterEventHotKey(
            UInt32(kVK_ISO_Section),
            modifiers,
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
        // Check for Ctrl+§
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let requiredFlags: NSEvent.ModifierFlags = [.control]

        // Key code for § (section sign) is 10 (kVK_ISO_Section)
        let isSectionKey = event.keyCode == UInt16(kVK_ISO_Section)
        let hasRequiredModifiers = flags == requiredFlags

        return isSectionKey && hasRequiredModifiers
    }
}
