import Foundation
import Observation

@MainActor @Observable
final class ActivationViewModel {
    var card: ScratchCard { repository.card }
    var status: ActivationStatus { manager.status }
    private let repository: any CardRepository
    private let manager: any ActivationManaging
    var isActivating: Bool { status == .running }
    var canActivate: Bool {
        if case .scratched = card { return !isActivating }
        return false
    }

    init(repository: any CardRepository, manager: any ActivationManaging) {
        self.repository = repository
        self.manager = manager
    }

    func activate() {
        guard canActivate else { return }
        manager.start()
    }
}
