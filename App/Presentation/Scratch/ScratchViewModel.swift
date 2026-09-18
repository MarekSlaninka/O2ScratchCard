import Foundation
import Observation

@MainActor @Observable
final class ScratchViewModel {
    var card: ScratchCard { repository.card }
    private(set) var isScratching = false
    var error: CardError?
    private let repository: any CardRepository
    private let useCase: any ScratchCardUseCase
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var operationID: UUID?
    var canScratch: Bool { card == .unscratched && !isScratching }

    init(repository: any CardRepository, useCase: any ScratchCardUseCase) {
        self.repository = repository
        self.useCase = useCase
    }

    func scratch() {
        guard canScratch else { return }
        let id = UUID()
        operationID = id
        isScratching = true
        error = nil
        let useCase = useCase
        task = Task { [weak self] in
            do {
                try await useCase.execute()
            } catch is CancellationError {

            } catch {
                guard let self, self.operationID == id else { return }
                self.error = (error as? CardError) ?? .network
            }
            guard let self, self.operationID == id else { return }
            self.isScratching = false
            self.task = nil
            self.operationID = nil
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        operationID = nil
        isScratching = false
    }
}
