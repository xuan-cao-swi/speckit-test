// Sources/App/Middleware/UserSessionAuthenticator.swift
// T010: Session-based authentication middleware for user identification

import Vapor
import Fluent

/// Authenticates users from session data
/// Uses Vapor's built-in session handling with our User model
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = PhotoAlbumOrganizer.User
    
    func authenticate(sessionID: User.SessionID, for request: Request) async throws {
        // Look up user by session ID (which is the user's UUID)
        if let user = try await User.find(sessionID, on: request.db) {
            request.auth.login(user)
        }
    }
}

/// Middleware that requires authentication
/// Returns 401 if no user is authenticated
struct UserGuardMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard request.auth.has(User.self) else {
            throw Abort(.unauthorized, reason: "Authentication required")
        }
        return try await next.respond(to: request)
    }
}

/// Extension to easily get the authenticated user from a request
extension Request {
    /// Returns the authenticated user or throws 401
    func requireUser() throws -> User {
        guard let user = auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "Authentication required")
        }
        return user
    }
    
    /// Returns the authenticated user or nil
    func getUser() -> User? {
        return auth.get(User.self)
    }
}
