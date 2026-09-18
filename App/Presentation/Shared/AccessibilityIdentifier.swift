enum AccessibilityIdentifier: String {
    case openScratch
    case openActivation
    case scratchButton
    case scratchSuccess
    case activateButton
    case activationSuccess
    case dismissActivationError
    case cardUnscratched = "cardState.unscratched"
    case cardScratched = "cardState.scratched"
    case cardActivated = "cardState.activated"
}
