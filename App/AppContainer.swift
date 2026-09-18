import Foundation

@MainActor
final class AppContainer {
    private let repository: any CardRepository
    private let scratchUseCase: any ScratchCardUseCase
    private let activationManager: any ActivationManaging
    let applicationViewModel: ApplicationViewModel
    let homeViewModel: HomeViewModel

    convenience init() {
        self.init(
            repository: InMemoryCardRepository(),
            service: HTTPActivationService(
                client: URLSessionHTTPClient(),
                endpoint: URL(string: "https://api.o2.sk/version")!
            )
        )
    }

    init(repository: any CardRepository, service: any ActivationService) {
        let activate = ActivateCard(repository: repository, service: service)
        let manager = ActivationManager(useCase: activate)
        self.repository = repository
        scratchUseCase = RevealCard(repository: repository, delay: TwoSecondDelay(), generator: UUIDGenerator())
        activationManager = manager
        applicationViewModel = ApplicationViewModel(manager: manager)
        homeViewModel = HomeViewModel(repository: repository)
    }

    static func forCurrentProcess() -> AppContainer {
        #if DEBUG
        if let service = UITestActivationService(arguments: ProcessInfo.processInfo.arguments) {
            return AppContainer(repository: InMemoryCardRepository(), service: service)
        }
        #endif
        return AppContainer()
    }

    func makeScratchViewModel() -> ScratchViewModel {
        ScratchViewModel(repository: repository, useCase: scratchUseCase)
    }

    func makeActivationViewModel() -> ActivationViewModel {
        ActivationViewModel(repository: repository, manager: activationManager)
    }
}

#if DEBUG

@MainActor
extension AppContainer {
    static let previewCode = UUID(uuidString: "12345678-1234-5678-ABCD-123456789ABC")!

    static func preview(card: ScratchCard = .unscratched) -> AppContainer {
        AppContainer(repository: InMemoryCardRepository(card: card), service: PreviewActivationService())
    }
}

/// Replaces the network during UI tests; selected by a launch argument so the
/// activation flow can be exercised without the real O2 endpoint.
struct UITestActivationService: ActivationService {
    static let succeedsArgument = "-uiTestActivationSucceeds"
    static let failsArgument = "-uiTestActivationFails"
    private let succeeds: Bool

    init?(arguments: [String]) {
        if arguments.contains(Self.succeedsArgument) {
            succeeds = true
        } else if arguments.contains(Self.failsArgument) {
            succeeds = false
        } else {
            return nil
        }
    }

    func fetchVersion(code: UUID) async throws -> AppVersion {
        try await Task.sleep(for: .seconds(1))
        guard succeeds else { throw CardError.network }
        return try AppVersion("6.24")
    }
}

private struct PreviewActivationService: ActivationService {
    func fetchVersion(code: UUID) async throws -> AppVersion {
        try await Task.sleep(for: .seconds(1))
        return try AppVersion("6.24")
    }
}
#endif
