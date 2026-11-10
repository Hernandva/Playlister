import Foundation
@testable import Networking
import Testing

struct RepositoryConfigurationTests {
    @Test func buildsTheURLOfADeclaredService() throws {
        let configuration = RepositoryConfiguration(baseURL: "https://api.example.com/v1", serviceNames: ["users"])
        #expect(try configuration.url(for: "users").absoluteString == "https://api.example.com/v1/users")
    }

    @Test func rejectsAnEmptyBaseURL() {
        let configuration = RepositoryConfiguration(baseURL: "", serviceNames: ["users"])
        #expect(throws: NetworkError.missingBaseURL) { try configuration.url(for: "users") }
    }

    @Test func rejectsAnUndeclaredService() {
        let configuration = RepositoryConfiguration(baseURL: "https://api.example.com", serviceNames: [])
        #expect(throws: NetworkError.unknownService("users")) { try configuration.url(for: "users") }
    }
}
