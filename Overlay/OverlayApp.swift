import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
}

@main
struct OverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup(id: "hidden") {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    init() {
        // Prevent the default window from showing
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
