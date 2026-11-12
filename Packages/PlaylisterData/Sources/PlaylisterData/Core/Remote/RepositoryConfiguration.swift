import Foundation

/// Where a repository's services live. Every repository declares one as `static let configuration`.
public struct RepositoryConfiguration: Sendable, Equatable {
    /// Base URL shared by the repository's services, e.g. "https://api.example.com/v1".
    public let baseURL: String
    /// Names (paths) of the services the repository consumes, e.g. ["users", "users/search"].
    public let serviceNames: [String]

    public init(baseURL: String, serviceNames: [String]) {
        self.baseURL = baseURL
        self.serviceNames = serviceNames
    }

    /// Full URL of one of the declared services.
    func url(for serviceName: String) throws -> URL {
        guard !baseURL.isEmpty else { throw NetworkError.missingBaseURL }
        guard serviceNames.contains(serviceName) else { throw NetworkError.unknownService(serviceName) }
        guard let base = URL(string: baseURL) else { throw NetworkError.invalidURL(baseURL) }
        return base.appendingPathComponent(serviceName)
    }
}
