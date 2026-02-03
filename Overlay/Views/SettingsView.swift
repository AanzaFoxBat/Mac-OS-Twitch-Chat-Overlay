import SwiftUI
import AppKit

struct NativeTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .exterior
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeTextField

        init(_ parent: NativeTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var urlText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // URL Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Twitch Chat URL")
                        .font(.headline)

                    NativeTextField(
                        text: $urlText,
                        placeholder: "https://www.twitch.tv/popout/channel/chat",
                        onSubmit: { settings.twitchChatURL = urlText }
                    )
                    .frame(height: 22)

                    Text("Enter the popout chat URL from Twitch")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Apply URL") {
                        settings.twitchChatURL = urlText
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlText == settings.twitchChatURL)
                }

                Divider()

                // Appearance Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.headline)

                    Toggle("Minimal chat style", isOn: $settings.minimalChatStyle)
                        .toggleStyle(.switch)

                    Text("Shows only usernames and messages with transparent background")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Text Size")
                        Spacer()
                        Picker("", selection: $settings.chatTextSize) {
                            ForEach(ChatTextSize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .disabled(!settings.minimalChatStyle)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Background Opacity")
                            Spacer()
                            Text("\(Int(settings.backgroundOpacity * 100))%")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.backgroundOpacity, in: 0...1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Content Opacity")
                            Spacer()
                            Text("\(Int(settings.contentOpacity * 100))%")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.contentOpacity, in: 0...1)
                    }
                }

                Divider()

                // Click-Through Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Click-Through Mode")
                        .font(.headline)

                    Toggle("Enable click-through", isOn: $settings.clickThroughEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.clickThroughEnabled) { newValue in
                            // Find the overlay window and update it directly
                            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                                appDelegate.overlayWindow?.ignoresMouseEvents = newValue
                                appDelegate.statusBarMenu?.updateMenu()
                            }
                        }

                    Text("When enabled, clicks pass through the overlay. Use Ctrl+§ to toggle.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Window Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window")
                        .font(.headline)

                    Button("Reset Window Position") {
                        for window in NSApplication.shared.windows {
                            if let overlayWindow = window as? OverlayWindow {
                                let defaultSize = NSSize(width: 400, height: 600)
                                let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
                                let newOrigin = NSPoint(
                                    x: screenFrame.midX - defaultSize.width / 2,
                                    y: screenFrame.midY - defaultSize.height / 2
                                )
                                let newFrame = NSRect(origin: newOrigin, size: defaultSize)
                                overlayWindow.setFrame(newFrame, display: true, animate: true)
                                break
                            }
                        }
                    }

                    Text("Centers the overlay window on screen with default size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .frame(minWidth: 400, maxWidth: 400)
        .onAppear {
            urlText = settings.twitchChatURL
        }
    }
}

#Preview {
    SettingsView()
}
