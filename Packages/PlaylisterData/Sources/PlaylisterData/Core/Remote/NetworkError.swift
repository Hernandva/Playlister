import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    /// The repository's `configuration.baseURL` is still empty.
    case missingBaseURL
    /// The service name is not listed in the repository's `configuration.serviceNames`.
    case unknownService(String)
    /// The base URL cannot be parsed.
    case invalidURL(String)
    /// The server answered with a status code outside 200…299, e.g. 401 for an expired token.
    case unacceptableStatusCode(Int)
}
