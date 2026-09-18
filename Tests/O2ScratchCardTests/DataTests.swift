@testable import O2ScratchCard
import Foundation
import Testing

@Suite("HTTP activation service")
@MainActor
struct DataTests {
    private let endpoint: URL

    init() throws {
        endpoint = try #require(URL(string: "https://api.o2.sk/version"))
    }

    @Test("The request carries the code and the response maps to a version")
    func requestAndResponseMapping() async throws {
        // Arrange
        let client = StubHTTPClient()
        let service = HTTPActivationService(client: client, endpoint: endpoint)
        let code = UUID()

        // Act
        let version = try await service.fetchVersion(code: code)

        // Assert
        #expect(version == (try AppVersion("6.24")))
        let requests = await client.requests
        let request = try #require(requests.first)
        #expect(request.httpMethod == "GET")
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "https")
        #expect(components.host == "api.o2.sk")
        #expect(components.path == "/version")
        #expect(components.queryItems == [URLQueryItem(name: "code", value: code.uuidString)])
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("A non-success status code surfaces as an HTTP status error")
    func httpFailure() async {
        // Arrange
        let service = HTTPActivationService(client: StubHTTPClient(status: 503), endpoint: endpoint)

        // Act & Assert
        await #expect(throws: CardError.httpStatus(503)) { try await service.fetchVersion(code: UUID()) }
    }

    @Test(
        "Malformed responses surface as an invalid response error",
        arguments: ["not json", "{}", "{\"ios\":6.24}", "{\"ios\":\"invalid\"}"]
    )
    func malformedResponses(body: String) async {
        // Arrange
        let service = HTTPActivationService(client: StubHTTPClient(body: body), endpoint: endpoint)

        // Act & Assert
        await #expect(throws: CardError.invalidResponse) { try await service.fetchVersion(code: UUID()) }
    }

    @Test("A transport failure surfaces as a network error")
    func networkFailure() async {
        // Arrange
        let client = StubHTTPClient(failure: URLError(.notConnectedToInternet))
        let service = HTTPActivationService(client: client, endpoint: endpoint)

        // Act & Assert
        await #expect(throws: CardError.network) { try await service.fetchVersion(code: UUID()) }
    }
}
