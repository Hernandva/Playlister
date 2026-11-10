import Alamofire
import Foundation

/// HTTP verbs available to repositories. Keeps Alamofire types out of repository code.
enum RequestMethod: Sendable {
    case get
    case post
    case put
    case patch
    case delete

    var alamofireMethod: HTTPMethod {
        switch self {
        case .get: .get
        case .post: .post
        case .put: .put
        case .patch: .patch
        case .delete: .delete
        }
    }
}

/// The only type in the project that talks to Alamofire.
/// Repositories receive it in their initialiser so tests can inject a session with stubbed responses.
public final class NetworkClient: @unchecked Sendable {
    // `Session` is thread safe; the client holds no mutable state.
    public static let shared = NetworkClient()

    private let session: Session

    public init(session: Session = .default) {
        self.session = session
    }

    /// Sends `body` (query string for GET, JSON otherwise) and decodes the response DAO.
    func request<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ url: URL,
        method: RequestMethod,
        body: Body?,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let encoder: any ParameterEncoder = method == .get
            ? URLEncodedFormParameterEncoder.default
            : JSONParameterEncoder.default
        return try await session
            .request(
                url,
                method: method.alamofireMethod,
                parameters: body,
                encoder: encoder,
                headers: HTTPHeaders(headers)
            )
            .validate()
            .serializingDecodable(Response.self)
            .value
    }
}
