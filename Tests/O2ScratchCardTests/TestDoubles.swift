@testable import O2ScratchCard
import Foundation
import Testing

struct FixedGenerator: CodeGenerator {
    let code: UUID
    func generate() -> UUID { code }
}

struct ImmediateDelay: ScratchDelay {
    func wait() async throws {}
}

actor ControlledDelay: ScratchDelay {
    private var pending: [CheckedContinuation<Void, Never>] = []
    private(set) var calls = 0

    func wait() async throws {
        calls += 1
        await withCheckedContinuation { pending.append($0) }
    }

    func release() {
        let current = pending
        pending.removeAll()
        for continuation in current { continuation.resume() }
    }
}

struct StubActivationService: ActivationService {
    let result: Result<AppVersion, CardError>
    func fetchVersion(code: UUID) async throws -> AppVersion { try result.get() }
}

actor ControlledActivationService: ActivationService {
    private var continuation: CheckedContinuation<AppVersion, Error>?
    private(set) var codes: [UUID] = []

    func fetchVersion(code: UUID) async throws -> AppVersion {
        codes.append(code)
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func complete(_ result: Result<AppVersion, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

actor StubHTTPClient: HTTPClient {
    let body: Data
    let status: Int
    let failure: URLError?
    private(set) var requests: [URLRequest] = []

    init(body: String = "{\"ios\":\"6.24\"}", status: Int = 200, failure: URLError? = nil) {
        self.body = Data(body.utf8)
        self.status = status
        self.failure = failure
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        if let failure { throw failure }
        let url = try #require(request.url)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)
        return (body, try #require(response))
    }
}

@MainActor
func eventually(_ predicate: () async -> Bool) async -> Bool {

    for _ in 0..<10_000 {
        if await predicate() { return true }
        await Task.yield()
    }
    return false
}
