import Foundation
import Observation

@MainActor @Observable
final class ActivationManager: ActivationManaging {
    private let useCase: any ActivateCardUseCase
    private(set) var status: ActivationStatus = .idle
    @ObservationIgnored private var task: Task<Void, Never>?

    init(useCase: any ActivateCardUseCase) { self.useCase = useCase }

    func start() {
        guard task == nil else { return }
        status = .running
        task = Task {
            do {
                try await useCase.execute()
                status = .idle
            } catch {
                status = .failed((error as? CardError) ?? .network)
            }
            task = nil
        }
    }

    func dismissError() {
        if case .failed = status { status = .idle }
    }
}
