import Foundation

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw CardError.invalidResponse }
        return (data, response)
    }
}

struct HTTPActivationService: ActivationService {
    private struct Response: Decodable { let ios: String }
    private let client: any HTTPClient
    private let endpoint: URL

    init(client: any HTTPClient, endpoint: URL) {
        self.client = client
        self.endpoint = endpoint
    }

    func fetchVersion(code: UUID) async throws -> AppVersion {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw CardError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "code", value: code.uuidString)]
        guard let url = components.url else { throw CardError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.data(for: request)
        } catch let error as CardError {
            throw error
        } catch {
            throw CardError.network
        }
        guard (200..<300).contains(response.statusCode) else { throw CardError.httpStatus(response.statusCode) }
        do {
            return try AppVersion(JSONDecoder().decode(Response.self, from: data).ios)
        } catch {
            throw CardError.invalidResponse
        }
    }
}
