import AppKit
import WebKit
import Combine

class OverlayViewController: NSViewController, WKNavigationDelegate {

    private var backgroundView: NSVisualEffectView!
    private var webView: WKWebView!
    private var dragAreaView: DragAreaView!

    private var cancellables = Set<AnyCancellable>()
    private let settings = AppSettings.shared

    override func loadView() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
        self.view = containerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
        setupWebView()
        setupDragArea()
        setupBindings()
        loadTwitchChat()
    }

    // MARK: - Setup

    private func setupBackgroundView() {
        backgroundView = NSVisualEffectView(frame: view.bounds)
        backgroundView.autoresizingMask = [.width, .height]
        backgroundView.wantsLayer = true

        // Apple-style glassmorphic effect
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.appearance = NSAppearance(named: .darkAqua)

        // Rounded corners
        backgroundView.layer?.cornerRadius = 12
        backgroundView.layer?.masksToBounds = true

        // Apply opacity
        backgroundView.alphaValue = CGFloat(settings.backgroundOpacity)

        view.addSubview(backgroundView)
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = false

        // Leave space for drag area at top (30px)
        let dragAreaHeight: CGFloat = 30
        let webViewFrame = NSRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: view.bounds.height - dragAreaHeight
        )

        webView = WKWebView(frame: webViewFrame, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self

        // Transparent background
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = .clear
        }

        // Hide scrollbars
        webView.enclosingScrollView?.hasVerticalScroller = false
        webView.enclosingScrollView?.hasHorizontalScroller = false

        webView.alphaValue = CGFloat(settings.contentOpacity)

        view.addSubview(webView)
    }

    private func setupDragArea() {
        // Create a draggable area at the top of the window (30px height)
        dragAreaView = DragAreaView(frame: NSRect(x: 0, y: view.bounds.height - 30, width: view.bounds.width, height: 30))
        dragAreaView.autoresizingMask = [.width, .minYMargin]
        view.addSubview(dragAreaView)
    }

    private func setupBindings() {
        settings.$backgroundOpacity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] opacity in
                self?.backgroundView.alphaValue = CGFloat(opacity)
            }
            .store(in: &cancellables)

        settings.$contentOpacity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] opacity in
                self?.webView.alphaValue = CGFloat(opacity)
            }
            .store(in: &cancellables)

        settings.$twitchChatURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadTwitchChat()
            }
            .store(in: &cancellables)

        settings.$minimalChatStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.injectMinimalStyleIfNeeded()
            }
            .store(in: &cancellables)

        settings.$chatTextSize
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.injectMinimalStyleIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func loadTwitchChat() {
        guard !settings.twitchChatURL.isEmpty,
              let url = URL(string: settings.twitchChatURL) else {
            // Load a placeholder if no URL is set
            let html = """
            <html>
            <head>
                <style>
                    body {
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        color: rgba(255, 255, 255, 0.6);
                        text-align: center;
                        background: transparent;
                    }
                    .placeholder {
                        padding: 20px;
                    }
                    h3 {
                        margin: 0 0 10px 0;
                        font-weight: 500;
                    }
                    p {
                        margin: 0;
                        font-size: 14px;
                        opacity: 0.7;
                    }
                </style>
            </head>
            <body>
                <div class="placeholder">
                    <h3>No Chat URL Set</h3>
                    <p>Open Settings to add your Twitch chat URL</p>
                </div>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
            return
        }

        webView.load(URLRequest(url: url))
    }

    private func injectMinimalStyleIfNeeded() {
        if settings.minimalChatStyle {
            injectMinimalCSS()
        } else {
            // Reload to remove injected styles
            loadTwitchChat()
        }
    }

    private func injectMinimalCSS() {
        let fontSize = settings.chatTextSize.fontSize
        let css = """
        /* Hide everything except chat messages */
        .stream-chat-header,
        .chat-input,
        .chat-input__buttons-container,
        .chat-room__content > div:first-child,
        [data-test-selector="chat-input"],
        [data-a-target="chat-input"],
        .chat-input-tray,
        .chat-wysiwyg-input__editor,
        .chat-settings,
        .community-points-summary,
        [class*="channel-leaderboard"],
        [class*="community-highlight"],
        [class*="predictions"],
        [class*="poll"],
        button,
        input {
            display: none !important;
        }

        /* Transparent background */
        body,
        html,
        .twilight-root,
        .tw-root--theme-dark,
        [class*="chat-room"],
        [class*="chat-shell"],
        .chat-scrollable-area__message-container,
        .simplebar-scroll-content,
        .simplebar-content,
        [data-a-target="chat-scroller"] {
            background: transparent !important;
            background-color: transparent !important;
        }

        /* Style messages */
        .chat-line__message {
            padding: 4px 8px !important;
            margin: 2px 0 !important;
            background: transparent !important;
            font-size: \(fontSize)px !important;
        }

        /* Username styling */
        .chat-author__display-name,
        [data-a-target="chat-message-username"] {
            font-weight: 600 !important;
            font-size: \(fontSize)px !important;
        }

        /* Message text */
        .text-fragment,
        [data-a-target="chat-message-text"] {
            color: white !important;
            font-size: \(fontSize)px !important;
        }

        /* Hide scrollbar */
        ::-webkit-scrollbar {
            display: none !important;
        }

        /* Remove borders and shadows */
        * {
            border: none !important;
            box-shadow: none !important;
        }
        """

        let js = """
        var style = document.getElementById('overlay-minimal-style');
        if (!style) {
            style = document.createElement('style');
            style.id = 'overlay-minimal-style';
            document.head.appendChild(style);
        }
        style.textContent = `\(css.replacingOccurrences(of: "\n", with: " "))`;
        """

        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("CSS injection error: \(error)")
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Always hide scrollbars
        injectScrollbarHidingCSS()

        // Inject CSS after page loads if minimal style is enabled
        if settings.minimalChatStyle {
            // Wait a bit for Twitch to fully render
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.injectMinimalCSS()
            }
        }
    }

    private func injectScrollbarHidingCSS() {
        let css = """
        ::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; }
        * { scrollbar-width: none !important; -ms-overflow-style: none !important; }
        html, body { overflow: -moz-scrollbars-none !important; }
        """

        let js = """
        var style = document.getElementById('overlay-scrollbar-hide');
        if (!style) {
            style = document.createElement('style');
            style.id = 'overlay-scrollbar-hide';
            document.head.appendChild(style);
        }
        style.textContent = `\(css.replacingOccurrences(of: "\n", with: " "))`;
        """

        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

// MARK: - Drag Area View

class DragAreaView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        // Draw a subtle grip indicator
        NSColor.white.withAlphaComponent(0.3).setFill()

        let gripWidth: CGFloat = 36
        let gripHeight: CGFloat = 5
        let gripRect = NSRect(
            x: (bounds.width - gripWidth) / 2,
            y: (bounds.height - gripHeight) / 2,
            width: gripWidth,
            height: gripHeight
        )

        let path = NSBezierPath(roundedRect: gripRect, xRadius: 2.5, yRadius: 2.5)
        path.fill()
    }
}
