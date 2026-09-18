import SwiftUI

@main
struct O2ScratchCardApp: App {
    @State private var container = AppContainer.forCurrentProcess()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .tint(.ocean)
        }
    }
}
