import SwiftUI

enum Route: Hashable {
    case scratch
    case activation
}

extension View {
    func navigationDestinations(container: AppContainer) -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .scratch: ScratchView(viewModel: container.makeScratchViewModel())
            case .activation: ActivationView(viewModel: container.makeActivationViewModel())
            }
        }
    }
}
