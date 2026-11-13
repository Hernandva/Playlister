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

/// How a request sends its body. `automatic` is a query string for GET and JSON otherwise.
enum RequestBodyEncoding: Sendable {
    case automatic
    /// `application/x-www-form-urlencoded`, e.g. for OAuth token endpoints.
    case form
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

    /// Sends `body` (query string for GET, JSON otherwise, unless `encoding` says so) and decodes the response DAO.
    /// A response outside 200…299 throws `NetworkError.unacceptableStatusCode`.
    /// With a `logLabel`, debug builds print the status code and the body of the response.
    func request<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ url: URL,
        method: RequestMethod,
        body: Body?,
        headers: [String: String] = [:],
        encoding: RequestBodyEncoding = .automatic,
        logLabel: String? = nil
    ) async throws -> Response {
        let encoder: any ParameterEncoder = method == .get || encoding == .form
            ? URLEncodedFormParameterEncoder.default
            : JSONParameterEncoder.default
        let request = session
            .request(
                url,
                method: method.alamofireMethod,
                parameters: body,
                encoder: encoder,
                headers: HTTPHeaders(headers)
            )
            .validate()
        #if DEBUG
        if let logLabel {
            await Self.log(request, label: logLabel)
        }
        #endif
        do {
            return try await request.serializingDecodable(Response.self).value
        } catch let error as AFError {
            if let statusCode = error.responseCode {
                throw NetworkError.unacceptableStatusCode(statusCode)
            }
            throw error
        }
    }

    #if DEBUG
    /// Prints the method, URL, status code and body of `request`'s response. Debug builds only.
    private static func log(_ request: DataRequest, label: String) async {
        let response = await request.serializingData().response
        let method = response.request?.httpMethod ?? "?"
        let url = response.request?.url?.absoluteString ?? "?"
        let status = response.response.map { String($0.statusCode) } ?? "no response"
        let body = response.data.flatMap { String(bytes: $0, encoding: .utf8) } ?? ""
        print("[\(label)] \(method) \(url) → \(status)\n\(body)")
        if let error = response.error, response.response == nil {
            print("[\(label)] error: \(error)")
        }
    }
    #endif
}
