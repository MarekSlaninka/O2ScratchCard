@testable import O2ScratchCard
import Foundation
import Observation
import Testing

@Suite("Screen view models")
@MainActor
struct PresentationTests {
    @Test("Repeated taps start one scratch and cancelling leaves the card untouched")
    func scratchDeduplicatesTapsAndCancelKeepsCardUnchanged() async {
        // Arrange
        let repository = InMemoryCardRepository()
        let delay = ControlledDelay()
        let useCase = RevealCard(repository: repository, delay: delay, generator: FixedGenerator(code: UUID()))
        let viewModel = ScratchViewModel(repository: repository, useCase: useCase)

        // Act
        viewModel.scratch()
        viewModel.scratch()

        // Assert
        #expect(viewModel.isScratching)
        #expect(viewModel.canScratch == false)
        let started = await eventually { await delay.calls == 1 }
        #expect(started)

        // Act
        viewModel.cancel()
        await delay.release()

        // Assert
        #expect(viewModel.isScratching == false)
        #expect(repository.card == .unscratched)
        #expect(viewModel.error == nil)
    }

    @Test("A completed scratch disables scratching again")
    func scratchCompletesAndDisablesRepeatedScratch() async {
        // Arrange
        let repository = InMemoryCardRepository()
        let code = UUID()
        let useCase = RevealCard(repository: repository, delay: ImmediateDelay(), generator: FixedGenerator(code: code))
        let viewModel = ScratchViewModel(repository: repository, useCase: useCase)

        // Act
        viewModel.scratch()
        let completed = await eventually { !viewModel.isScratching }

        // Assert
        #expect(completed)
        #expect(viewModel.card == .scratched(code: code))
        #expect(viewModel.canScratch == false)

        // Act
        viewModel.cancel()

        // Assert
        #expect(repository.card == .scratched(code: code))
    }

    @Test("Activation outlives its screen and deduplicates concurrent requests")
    func activationSurvivesScreenDisposalAndDeduplicatesRequests() async throws {
        // Arrange
        let code = UUID()
        let repository = InMemoryCardRepository(card: .scratched(code: code))
        let service = ControlledActivationService()
        let useCase = ActivateCard(repository: repository, service: service, minimumVersion: try AppVersion("6.1"))
        let manager = ActivationManager(useCase: useCase)
        var viewModel: ActivationViewModel? = ActivationViewModel(repository: repository, manager: manager)
        weak let weakViewModel = viewModel

        // Act
        viewModel?.activate()
        viewModel?.activate()
        manager.start()
        viewModel = nil

        // Assert
        #expect(weakViewModel == nil)
        let started = await eventually { await service.codes.count == 1 }
        #expect(started)
        let reopened = ActivationViewModel(repository: repository, manager: manager)
        #expect(reopened.isActivating)
        #expect(reopened.canActivate == false)

        // Act
        await service.complete(.success(try AppVersion("6.24")))
        let completed = await eventually { manager.status == .idle }

        // Assert
        #expect(completed)
        #expect(repository.card == .activated(code: code))
        let sentCodes = await service.codes
        #expect(sentCodes == [code])
    }

    @Test("A failed activation is presented globally and can be retried")
    func failureIsPresentedGloballyAndCanBeRetried() async throws {
        // Arrange
        let code = UUID()
        let repository = InMemoryCardRepository(card: .scratched(code: code))
        let service = ControlledActivationService()
        let useCase = ActivateCard(repository: repository, service: service, minimumVersion: try AppVersion("6.1"))
        let manager = ActivationManager(useCase: useCase)
        let application = ApplicationViewModel(manager: manager)

        // Act
        manager.start()
        let started = await eventually { await service.codes.count == 1 }

        // Assert
        #expect(started)

        // Act
        await service.complete(.failure(CardError.network))
        let failed = await eventually { application.error != nil }

        // Assert
        #expect(failed)
        #expect(repository.card == .scratched(code: code))

        // Act
        application.dismissError()

        // Assert
        #expect(application.error == nil)
        #expect(manager.status == .idle)

        // Act
        manager.start()
        let retried = await eventually { await service.codes.count == 2 }

        // Assert
        #expect(retried)

        // Act
        await service.complete(.success(try AppVersion("7")))
        let completed = await eventually { repository.card == .activated(code: code) }

        // Assert
        #expect(completed)
    }

    @Test("Home and activation observe the same shared card state")
    func homeAndActivationObserveSharedState() async throws {
        // Arrange
        let repository = InMemoryCardRepository()
        let service = StubActivationService(result: .success(try AppVersion("7")))
        let useCase = ActivateCard(repository: repository, service: service, minimumVersion: try AppVersion("6.1"))
        let manager = ActivationManager(useCase: useCase)
        let home = HomeViewModel(repository: repository)
        let activation = ActivationViewModel(repository: repository, manager: manager)

        // Assert
        #expect(activation.canActivate == false)

        // Arrange
        let code = UUID()

        // Act
        try repository.reveal(code: code)
        let observed = await eventually { home.card == .scratched(code: code) && activation.canActivate }

        // Assert
        #expect(observed)

        // Act
        activation.activate()
        let completed = await eventually {
            home.card == .activated(code: code) && !activation.isActivating && !activation.canActivate
        }

        // Assert
        #expect(completed)
    }

    @Test("A card change invalidates every screen view model")
    func cardChangesInvalidateAllScreenViewModels() async throws {
        // Arrange
        let repository = InMemoryCardRepository()
        let generator = FixedGenerator(code: UUID())
        let revealCard = RevealCard(repository: repository, delay: ImmediateDelay(), generator: generator)
        let service = StubActivationService(result: .success(try AppVersion("7")))
        let activateCard = ActivateCard(repository: repository, service: service, minimumVersion: try AppVersion("6.1"))
        let home = HomeViewModel(repository: repository)
        let scratch = ScratchViewModel(repository: repository, useCase: revealCard)
        let activation = ActivationViewModel(repository: repository, manager: ActivationManager(useCase: activateCard))
        let code = UUID()

        // Act & Assert
        try await confirmation("Home state invalidated") { homeChanged in
            try await confirmation("Scratch state invalidated") { scratchChanged in
                try await confirmation("Activation state invalidated") { activationChanged in
                    withObservationTracking { _ = home.card } onChange: { homeChanged() }
                    withObservationTracking { _ = scratch.canScratch } onChange: { scratchChanged() }
                    withObservationTracking { _ = activation.canActivate } onChange: { activationChanged() }

                    try repository.reveal(code: code)
                }
            }
        }

        // Assert
        #expect(home.card == .scratched(code: code))
        #expect(scratch.card == home.card)
        #expect(scratch.canScratch == false)
        #expect(activation.canActivate)
    }

    @Test("Activation and the global error invalidate without subscription tasks")
    func activationAndGlobalErrorInvalidateWithoutSubscriptionTasks() async throws {
        // Arrange
        let repository = InMemoryCardRepository(card: .scratched(code: UUID()))
        let service = ControlledActivationService()
        let useCase = ActivateCard(repository: repository, service: service, minimumVersion: try AppVersion("6.1"))
        let manager = ActivationManager(useCase: useCase)
        let activation = ActivationViewModel(repository: repository, manager: manager)
        let application = ApplicationViewModel(manager: manager)

        // Act & Assert
        await confirmation("Activation state invalidated") { startedNotification in
            withObservationTracking { _ = activation.isActivating } onChange: { startedNotification() }

            activation.activate()
            let started = await eventually { await service.codes.count == 1 }
            #expect(started)
        }

        // Assert
        #expect(activation.isActivating)

        // Act & Assert
        await confirmation("Global error invalidated") { errorNotification in
            withObservationTracking { _ = application.error } onChange: { errorNotification() }

            await service.complete(.failure(CardError.network))
            let failed = await eventually { application.error == .network }
            #expect(failed)
        }

        // Assert
        #expect(activation.isActivating == false)

        // Act & Assert
        await confirmation("Error dismissal invalidated") { dismissalNotification in
            withObservationTracking { _ = application.error } onChange: { dismissalNotification() }

            application.dismissError()
        }

        // Assert
        #expect(application.error == nil)
    }
}
