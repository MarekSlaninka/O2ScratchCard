import Foundation

enum ScratchCard: Equatable, Sendable {
    case unscratched
    case scratched(code: UUID)
    case activated(code: UUID)
    
    var code: UUID? {
        switch self {
        case .unscratched: nil
        case .scratched(let code), .activated(let code): code
        }
    }
}

enum CardError: Error, Equatable, Sendable {
    case alreadyScratched
    case notScratched
    case alreadyActivated
    case codeMismatch
    case unsupportedVersion
    case invalidResponse
    case httpStatus(Int)
    case network
}

@MainActor
protocol CardRepository: AnyObject {
    var card: ScratchCard { get }
    func reveal(code: UUID) throws
    func activate(code: UUID) throws
}

protocol ScratchDelay: Sendable {
    func wait() async throws
}

protocol CodeGenerator: Sendable {
    func generate() -> UUID
}

protocol ActivationService: Sendable {
    func fetchVersion(code: UUID) async throws -> AppVersion
}
