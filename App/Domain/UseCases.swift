import Foundation

@MainActor
protocol ScratchCardUseCase {
    func execute() async throws
}

@MainActor
final class RevealCard: ScratchCardUseCase {
    private let repository: any CardRepository
    private let delay: any ScratchDelay
    private let generator: any CodeGenerator

    init(repository: any CardRepository, delay: any ScratchDelay, generator: any CodeGenerator) {
        self.repository = repository
        self.delay = delay
        self.generator = generator
    }

    func execute() async throws {
        guard repository.card == .unscratched else { throw CardError.alreadyScratched }
        try await delay.wait()

        try Task.checkCancellation()
        try repository.reveal(code: generator.generate())
    }
}

@MainActor
protocol ActivateCardUseCase {
    func execute() async throws
}

extension AppVersion {
    static let activationThreshold = AppVersion(major: 6, minor: 1)
}

@MainActor
final class ActivateCard: ActivateCardUseCase {
    private let repository: any CardRepository
    private let service: any ActivationService
    private let minimumVersion: AppVersion

    init(
        repository: any CardRepository,
        service: any ActivationService,
        minimumVersion: AppVersion = .activationThreshold
    ) {
        self.repository = repository
        self.service = service
        self.minimumVersion = minimumVersion
    }

    func execute() async throws {
        let code: UUID
        switch repository.card {
        case .unscratched: throw CardError.notScratched
        case .activated: throw CardError.alreadyActivated
        case .scratched(let value): code = value
        }
        let version = try await service.fetchVersion(code: code)
        guard version > minimumVersion else { throw CardError.unsupportedVersion }
        try repository.activate(code: code)
    }
}

enum ActivationStatus: Equatable, Sendable {
    case idle
    case running
    case failed(CardError)
}

@MainActor
protocol ActivationManaging: AnyObject {
    var status: ActivationStatus { get }
    func start()
    func dismissError()
}
