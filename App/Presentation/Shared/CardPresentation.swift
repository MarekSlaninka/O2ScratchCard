import Foundation

extension CardError {
    var message: LocalizedStringResource {
        switch self {
        case .alreadyScratched: .errorAlreadyScratched
        case .notScratched: .errorNotScratched
        case .alreadyActivated: .errorAlreadyActivated
        case .codeMismatch: .errorCodeMismatch
        case .unsupportedVersion: .errorUnsupportedVersion
        case .invalidResponse: .errorInvalidResponse
        case .httpStatus(let code): .errorHttpStatus(code)
        case .network: .errorNetwork
        }
    }
}

extension ScratchCard {
    var title: LocalizedStringResource {
        switch self {
        case .unscratched: .cardUnscratched
        case .scratched: .cardScratched
        case .activated: .cardActivated
        }
    }

    func statusDescription(locale: Locale) -> LocalizedStringResource {
        var localizedTitle = title
        localizedTitle.locale = locale
        var description = LocalizedStringResource.homeStatus(String(localized: localizedTitle))
        description.locale = locale
        return description
    }

    var accessibilityIdentifier: AccessibilityIdentifier {
        switch self {
        case .unscratched: .cardUnscratched
        case .scratched: .cardScratched
        case .activated: .cardActivated
        }
    }

    var symbol: String {
        switch self {
        case .unscratched: "lock.fill"
        case .scratched: "key.fill"
        case .activated: "checkmark.seal.fill"
        }
    }
}
