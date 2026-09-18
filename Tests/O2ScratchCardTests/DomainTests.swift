@testable import O2ScratchCard
import Foundation
import Testing

@Suite("AppVersion parsing and ordering")
struct VersionTests {
    @Test("Numeric versions order correctly and normalize trailing zeroes")
    func numericVersionOrderingAndNormalization() throws {
        // Arrange
        let values = ["6.24", "6.1", "6.10", "6.2", "6.1.1", "6.1.0", "6.0"]

        // Act
        let versions = try values.map { try AppVersion($0) }

        // Assert
        #expect(versions[0] > versions[1])
        #expect(versions[2] > versions[3])
        #expect(versions[4] > versions[1])
        #expect(versions[5] == versions[1])
        #expect(versions[6] < versions[1])
        #expect(AppVersion(major: 6, minor: 1) == versions[1])
        #expect(AppVersion(major: 6, minor: 1, patch: 1) == versions[4])
        #expect(try AppVersion("7.0.0") == AppVersion(major: 7))
    }

    @Test(
        "Malformed versions are rejected",
        arguments: ["", "6..1", ".6", "6.", "-1", "6.beta", " 6.2", "6.2 ", "999999999999999999999999999"]
    )
    func malformedVersionsAreRejected(value: String) {
        // Act & Assert
        #expect(throws: CardError.invalidResponse) { try AppVersion(value) }
    }
}

@Suite("Scratch card domain")
@MainActor
struct DomainTests {
    @Test("The repository enforces the card state machine")
    func initialStateAndAllowedTransitions() throws {
        // Arrange
        let repository = InMemoryCardRepository()
        let code = UUID()

        // Assert
        #expect(repository.card == .unscratched)

        // Act & Assert
        #expect(throws: CardError.notScratched) { try repository.activate(code: code) }

        // Act
        try repository.reveal(code: code)

        // Act & Assert
        #expect(throws: CardError.alreadyScratched) { try repository.reveal(code: UUID()) }
        #expect(throws: CardError.codeMismatch) { try repository.activate(code: UUID()) }
        #expect(repository.card == .scratched(code: code))

        // Act
        try repository.activate(code: code)

        // Assert
        #expect(repository.card == .activated(code: code))

        // Act & Assert
        #expect(throws: CardError.alreadyScratched) { try repository.reveal(code: UUID()) }
        #expect(throws: CardError.alreadyActivated) { try repository.activate(code: code) }
    }

    @Test("Scratching waits for the delay before revealing the code")
    func scratchWaitsBeforeRevealingCode() async throws {
        // Arrange
        let repository = InMemoryCardRepository()
        let delay = ControlledDelay()
        let code = UUID()
        let useCase = RevealCard(repository: repository, delay: delay, generator: FixedGenerator(code: code))

        // Act
        let task = Task { try await useCase.execute() }
        let started = await eventually { await delay.calls == 1 }

        // Assert
        #expect(started)
        #expect(repository.card == .unscratched)

        // Act
        await delay.release()
        try await task.value

        // Assert
        #expect(repository.card == .scratched(code: code))
    }

    @Test("A cancelled scratch cannot commit a late result")
    func cancelledScratchCannotCommitLateResult() async {
        // Arrange
        let repository = InMemoryCardRepository()
        let delay = ControlledDelay()
        let useCase = RevealCard(repository: repository, delay: delay, generator: FixedGenerator(code: UUID()))

        // Act
        let task = Task { try await useCase.execute() }
        let started = await eventually { await delay.calls == 1 }

        // Assert
        #expect(started)

        // Act
        task.cancel()
        await delay.release()

        // Assert
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(repository.card == .unscratched)
    }

    @Test("Scratching an already scratched card preserves the original code")
    func repeatedScratchPreservesCode() async throws {
        // Arrange
        let code = UUID()
        let repository = InMemoryCardRepository(card: .scratched(code: code))
        let generator = FixedGenerator(code: UUID())
        let useCase = RevealCard(repository: repository, delay: ImmediateDelay(), generator: generator)

        // Act & Assert
        await #expect(throws: CardError.alreadyScratched) { try await useCase.execute() }

        // Assert
        #expect(repository.card == .scratched(code: code))
    }

    @Test(
        "Activation only succeeds above the minimum version",
        arguments: ["6.0", "6.1", "6.1.0", "6.1.1", "6.24", "7"]
    )
    func activationThreshold(version: String) async throws {
        // Arrange
        let code = UUID()
        let repository = InMemoryCardRepository(card: .scratched(code: code))
        let parsed = try AppVersion(version)
        let threshold = try AppVersion("6.1")
        let service = StubActivationService(result: .success(parsed))
        let useCase = ActivateCard(repository: repository, service: service, minimumVersion: threshold)

        // Act & Assert
        do {
            try await useCase.execute()

            // Assert
            #expect(parsed > threshold)
            #expect(repository.card == .activated(code: code))
        } catch {
            // Assert
            #expect(parsed <= threshold)
            #expect(error as? CardError == .unsupportedVersion)
            #expect(repository.card == .scratched(code: code))
        }
    }

    @Test(
        "Activation is rejected unless the card is scratched",
        arguments: [ScratchCard.unscratched, .activated(code: UUID())]
    )
    func activationRequiresScratchedCard(card: ScratchCard) async throws {
        // Arrange
        let repository = InMemoryCardRepository(card: card)
        let service = ControlledActivationService()
        let useCase = ActivateCard(repository: repository, service: service, minimumVersion: try AppVersion("6.1"))
        let expectedError: CardError = card == .unscratched ? .notScratched : .alreadyActivated

        // Act & Assert
        await #expect(throws: expectedError) { try await useCase.execute() }

        // Assert
        let codes = await service.codes
        #expect(codes.isEmpty)
    }
}
