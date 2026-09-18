import Foundation
import Observation

@MainActor @Observable
final class InMemoryCardRepository: CardRepository {
    private(set) var card: ScratchCard

    init(card: ScratchCard = .unscratched) { self.card = card }

    func reveal(code: UUID) throws {
        guard card == .unscratched else { throw CardError.alreadyScratched }
        card = .scratched(code: code)
    }

    func activate(code: UUID) throws {
        switch card {
        case .unscratched: throw CardError.notScratched
        case .activated: throw CardError.alreadyActivated
        case .scratched(let current) where current != code: throw CardError.codeMismatch
        case .scratched: card = .activated(code: code)
        }
    }
}

struct TwoSecondDelay: ScratchDelay {
    init() {}
    func wait() async throws { try await Task.sleep(for: .seconds(2)) }
}

struct UUIDGenerator: CodeGenerator {
    init() {}
    func generate() -> UUID { UUID() }
}
