import SwiftUI

struct ScratchView: View {
    @AccessibilityFocusState private var isSuccessFocused: Bool
    @State var viewModel: ScratchViewModel

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 8) {
                Text(.scratchHeadline).font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                Text(.scratchDescription)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            CardPanel(card: viewModel.card)
            if viewModel.isScratching {
                ProgressNotice(text: .scratchProgress)
            }
            Button(action: viewModel.scratch) {
                ActionLabel(title: viewModel.card.code == nil ? .scratchAction : .scratchRevealed, symbol: "sparkles")
            }
            .buttonStyle(CardActionStyle())
            .disabled(!viewModel.canScratch)
            .accessibilityIdentifier(.scratchButton)
            if viewModel.card.code != nil {
                Label(.scratchSuccess, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(.scratchSuccess)
                    .accessibilityFocused($isSuccessFocused)
            }
        }
        .navigationTitle(.scratchTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.card) { previous, current in
            if previous.code == nil, current.code != nil { isSuccessFocused = true }
        }
        .onDisappear { viewModel.cancel() }
        .alert(.scratchErrorTitle, isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button(.commonDismiss, role: .cancel) { viewModel.error = nil }
        } message: { if let error = viewModel.error { Text(error.message) } }
    }
}

#if DEBUG
#Preview("Pred zotretím") {
    let container = AppContainer.preview()
    NavigationStack {
        ScratchView(viewModel: container.makeScratchViewModel())
    }
    .tint(.ocean)
}

#Preview("Odhalený kód") {
    let container = AppContainer.preview(card: .scratched(code: AppContainer.previewCode))
    NavigationStack {
        ScratchView(viewModel: container.makeScratchViewModel())
    }
    .tint(.ocean)
}
#endif
