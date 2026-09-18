import Foundation
import Observation

@MainActor @Observable
final class HomeViewModel {
    var card: ScratchCard { repository.card }
    private let repository: any CardRepository

    init(repository: any CardRepository) {
        self.repository = repository
    }

}
