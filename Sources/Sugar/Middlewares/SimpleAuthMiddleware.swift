import HTTP
import Vapor
import AuthProvider

public final class SimpleAuthMiddleware: Middleware {
    private let token: String

    public init(token: String) {
        self.token = token
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {

        guard
            let header = request.auth.header,
            header.string == token
        else {
            throw Abort.unauthorized
        }

        return try next.respond(to: request)
    }
}