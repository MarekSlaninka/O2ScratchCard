import SwiftUI

struct RootView: View {
    @Environment(\.locale) private var locale
    let container: AppContainer

    var body: some View {
        NavigationStack {
            HomeView(viewModel: container.homeViewModel)
                .navigationDestinations(container: container)
        }
        #if DEBUG
        .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("-uiTestDarkMode") ? .dark : nil)
        #endif
        .onChange(of: container.homeViewModel.card) { previous, current in
            guard previous != current, case .activated = current else { return }
            var message = LocalizedStringResource.activationSuccess
            message.locale = locale
            AccessibilityNotification.Announcement(String(localized: message)).post()
        }
        .alert(.activationErrorTitle, isPresented: Binding(
            get: { container.applicationViewModel.error != nil },
            set: { if !$0 { container.applicationViewModel.dismissError() } }
        )) {
            Button(.commonDismiss, role: .cancel) { container.applicationViewModel.dismissError() }
                .accessibilityIdentifier(.dismissActivationError)
        } message: {
            if let error = container.applicationViewModel.error { Text(error.message) }
        }
    }
}

#if DEBUG
#Preview("Celá aplikácia") {
    RootView(container: .preview())
        .tint(.ocean)
}
#endif
