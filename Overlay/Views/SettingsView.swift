import SwiftUI
import AppKit
import Carbon.HIToolbox

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
    @State private var newKeyword: String = ""

    private var availableFonts: [String] {
        var fonts = ["System"]
        fonts.append(contentsOf: NSFontManager.shared.availableFontFamilies.sorted())
        return fonts
    }

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

                Divider()

                // Advanced Options Section
                DisclosureGroup("Advanced Options", isExpanded: $settings.advancedOptionsEnabled) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Custom Hotkey
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom Hotkey")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HotkeyRecorderView(
                                keyCode: $settings.hotkeyKeyCode,
                                modifiers: $settings.hotkeyModifiers
                            )
                            .frame(height: 22)

                            Text("Click to record a new hotkey for toggling click-through mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)

                        Divider()

                        // Chat Font
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Chat Font")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Picker("Font Family", selection: $settings.chatFontFamily) {
                                ForEach(availableFonts, id: \.self) { font in
                                    Text(font).tag(font)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()

                            Text("Requires Minimal Style to be enabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Keyword Alerts
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Keyword Alerts")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                NativeTextField(
                                    text: $newKeyword,
                                    placeholder: "Enter keyword",
                                    onSubmit: addKeyword
                                )
                                .frame(height: 22)

                                Button("Add") {
                                    addKeyword()
                                }
                                .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
                            }

                            // Keyword chips
                            if !settings.alertKeywords.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(settings.alertKeywords, id: \.self) { keyword in
                                        HStack(spacing: 4) {
                                            Text(keyword)
                                                .font(.caption)
                                            Button(action: {
                                                removeKeyword(keyword)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }

                            HStack {
                                Text("Highlight Color")
                                Spacer()
                                ColorPicker("", selection: Binding(
                                    get: { Color(hex: settings.alertHighlightColor) ?? .yellow },
                                    set: { settings.alertHighlightColor = $0.toHex() }
                                ))
                                .labelsHidden()
                            }

                            Text("Messages containing these keywords will be highlighted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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

    private func addKeyword() {
        let keyword = newKeyword.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty, !settings.alertKeywords.contains(keyword) else { return }
        settings.alertKeywords.append(keyword)
        newKeyword = ""
    }

    private func removeKeyword(_ keyword: String) {
        settings.alertKeywords.removeAll { $0 == keyword }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b: Double
        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components else {
            return "#FFFF00"
        }

        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, placement) in result.placements.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + placement.x, y: bounds.minY + placement.y),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, placements: [(x: CGFloat, y: CGFloat, size: CGSize)]) {
        let maxWidth = proposal.width ?? .infinity

        var placements: [(x: CGFloat, y: CGFloat, size: CGSize)] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            placements.append((x: currentX, y: currentY, size: size))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = max(totalHeight, currentY + lineHeight)
        }

        return (CGSize(width: totalWidth, height: totalHeight), placements)
    }
}

#Preview {
    SettingsView()
}
