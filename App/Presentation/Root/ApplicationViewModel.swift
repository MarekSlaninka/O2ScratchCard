import Foundation
import Observation

@MainActor @Observable
final class ApplicationViewModel {
    var error: CardError? {
        if case .failed(let error) = manager.status { return error }
        return nil
    }
    private let manager: any ActivationManaging

    init(manager: any ActivationManaging) { self.manager = manager }

    func dismissError() {
        manager.dismissError()
    }
}
