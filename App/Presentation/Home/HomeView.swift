import SwiftUI

struct HomeView: View {
    @Environment(\.locale) private var locale
    @State var viewModel: HomeViewModel

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 8) {
                Text(.homeHeadline).font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                Text(.homeDescription)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            CardPanel(card: viewModel.card)
            VStack(spacing: 14) {
                NavigationLink(value: Route.scratch) {
                    ActionLabel(title: .scratchAction, symbol: "sparkles")
                }
                .buttonStyle(CardActionStyle())
                .accessibilityIdentifier(.openScratch)
                NavigationLink(value: Route.activation) {
                    ActionLabel(title: .activationAction, symbol: "bolt.fill")
                }
                .buttonStyle(CardActionStyle(prominent: false))
                .accessibilityIdentifier(.openActivation)
                .accessibilityValue(viewModel.card == .unscratched ? Text(.homeActivationRequiresScratch) : Text(""))
            }
            Label(viewModel.card.statusDescription(locale: locale), systemImage: viewModel.card.symbol)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview("Nezotretá karta") {
    let container = AppContainer.preview()
    NavigationStack {
        HomeView(viewModel: container.homeViewModel)
            .navigationDestinations(container: container)
    }
    .tint(.ocean)
}

#Preview("Zotretá karta") {
    let container = AppContainer.preview(card: .scratched(code: AppContainer.previewCode))
    NavigationStack {
        HomeView(viewModel: container.homeViewModel)
            .navigationDestinations(container: container)
    }
    .tint(.ocean)
}

#Preview("Aktivovaná karta · tmavý režim") {
    let container = AppContainer.preview(card: .activated(code: AppContainer.previewCode))
    NavigationStack {
        HomeView(viewModel: container.homeViewModel)
            .navigationDestinations(container: container)
    }
    .tint(.ocean)
    .preferredColorScheme(.dark)
}
#endif
