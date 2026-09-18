import SwiftUI

struct ActivationView: View {
    @State var viewModel: ActivationViewModel

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 8) {
                Text(.activationHeadline).font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                Text(.activationDescription)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            CardPanel(card: viewModel.card)
            if viewModel.isActivating {
                ProgressNotice(text: .activationProgress)
            }
            Button(action: viewModel.activate) {
                ActionLabel(title: .activationAction, symbol: "bolt.fill")
            }
            .buttonStyle(CardActionStyle())
            .disabled(!viewModel.canActivate)
            .accessibilityIdentifier(.activateButton)
            .accessibilityValue(viewModel.card == .unscratched ? Text(.activationRequiresScratch) : Text(""))
            switch viewModel.card {
            case .unscratched:
                Label(.activationRequiresScratch, systemImage: "info.circle")
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            case .scratched:
                Label(.activationContinues, systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            case .activated:
                Label(.activationSuccess, systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(.activationSuccess)
            }
        }
        .navigationTitle(.activationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Karta ešte nie je zotretá") {
    let container = AppContainer.preview()
    NavigationStack {
        ActivationView(viewModel: container.makeActivationViewModel())
    }
    .tint(.ocean)
}

#Preview("Pripravená na aktiváciu") {
    let container = AppContainer.preview(card: .scratched(code: AppContainer.previewCode))
    NavigationStack {
        ActivationView(viewModel: container.makeActivationViewModel())
    }
    .tint(.ocean)
}

#Preview("Úspešná aktivácia") {
    let container = AppContainer.preview(card: .activated(code: AppContainer.previewCode))
    NavigationStack {
        ActivationView(viewModel: container.makeActivationViewModel())
    }
    .tint(.ocean)
}
#endif
