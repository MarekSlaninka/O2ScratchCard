import SwiftUI

extension View {
    func accessibilityIdentifier(_ identifier: AccessibilityIdentifier) -> some View {
        accessibilityIdentifier(identifier.rawValue)
    }
}

extension Color {
    static let ocean = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.75, blue: 1, alpha: 1)
            : UIColor(red: 0, green: 0.36, blue: 0.72, alpha: 1)
    })
    static let cardBlue = Color(red: 0, green: 0.36, blue: 0.72)
    static let cardDeep = Color(red: 0.02, green: 0.15, blue: 0.37)
}

struct Screen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) { content }
                .padding(24)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct CardPanel: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var logoSize = 42
    let card: ScratchCard

    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerLayout {
                Text(verbatim: "O₂").font(.system(size: logoSize, weight: .bold, design: .rounded))
                    .accessibilityHidden(true)
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                Label(card.title, systemImage: card.symbol)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(card.accessibilityIdentifier)
            }
            Spacer(minLength: 8)
            Text(.cardTitle)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            if let code = card.code {
                Text(verbatim: code.uuidString)
                    .font(.system(.subheadline, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(.cardCodeAccessibility(code.uuidString))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .accessibilityHidden(true)
                    Text(.cardHiddenCode)
                }
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardDeep, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.cardBlue, .cardDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
}

struct ActionLabel: View {
    let title: LocalizedStringResource
    let symbol: String
    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 10)
    }
}

struct CardActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        let filled = prominent && isEnabled
        configuration.label
            .padding(.horizontal, 12)
            .foregroundStyle(filled ? Color.white : Color(uiColor: .label))
            .background(filled ? Color.cardBlue : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(filled ? Color.clear : Color(uiColor: .label), lineWidth: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.08 : 0))
            }
    }
}

struct ProgressNotice: View {
    @Environment(\.locale) private var locale
    let text: LocalizedStringResource
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(text).font(.subheadline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(text))
        .onAppear {
            var message = text
            message.locale = locale
            AccessibilityNotification.Announcement(String(localized: message)).post()
        }
    }
}

#if DEBUG
#Preview("Screen · stavy karty") {
    Screen {
        CardPanel(card: .unscratched)
        CardPanel(card: .scratched(code: AppContainer.previewCode))
        CardPanel(card: .activated(code: AppContainer.previewCode))
    }
}

#Preview("CardPanel · veľké písmo", traits: .sizeThatFitsLayout) {
    CardPanel(card: .scratched(code: AppContainer.previewCode))
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("ActionLabel", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        Button {} label: {
            ActionLabel(title: .scratchAction, symbol: "sparkles")
        }
        .buttonStyle(CardActionStyle())
        Button {} label: {
            ActionLabel(title: .activationAction, symbol: "bolt.fill")
        }
        .buttonStyle(CardActionStyle(prominent: false))
    }
    .tint(.ocean)
    .padding()
}

#Preview("ProgressNotice", traits: .sizeThatFitsLayout) {
    ProgressNotice(text: .activationProgress)
        .padding()
}
#endif
