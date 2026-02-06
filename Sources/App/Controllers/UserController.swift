// Sources/App/Controllers/UserController.swift
// T011: User controller for login, logout, and current user endpoints

import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        // Public routes
        users.post("login", use: login)
        
        // Protected routes (require session)
        let protected = users.grouped(UserSessionAuthenticator())
            .grouped(UserGuardMiddleware())
        protected.post("logout", use: logout)
        protected.get("me", use: getCurrentUser)
    }
    
    // MARK: - Login
    
    /// POST /api/users/login
    /// Creates a session for the user (creates user if doesn't exist)
    @Sendable
    func login(req: Request) async throws -> UserResponse {
        let input = try req.content.decode(LoginRequest.self)
        
        // Validate username format
        guard input.username.count >= 3 && input.username.count <= 50 else {
            throw Abort(.badRequest, reason: "Username must be 3-50 characters")
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        guard input.username.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw Abort(.badRequest, reason: "Username can only contain letters, numbers, hyphens, and underscores")
        }
        
        // Find or create user
        let user: User
        if let existingUser = try await User.query(on: req.db)
            .filter(\.$username == input.username)
            .first() {
            user = existingUser
        } else {
            // Create new user
            user = User(username: input.username)
            try await user.save(on: req.db)
        }
        
        // Create session
        req.auth.login(user)
        req.session.authenticate(user)
        
        return UserResponse(
            id: try user.requireID(),
            username: user.username,
            createdAt: user.createdAt
        )
    }
    
    // MARK: - Logout
    
    /// POST /api/users/logout
    /// Destroys the current session
    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        req.auth.logout(User.self)
        req.session.unauthenticate(User.self)
        req.session.destroy()
        return .noContent
    }
    
    // MARK: - Get Current User
    
    /// GET /api/users/me
    /// Returns the currently authenticated user
    @Sendable
    func getCurrentUser(req: Request) async throws -> UserResponse {
        let user = try req.requireUser()
        return UserResponse(
            id: try user.requireID(),
            username: user.username,
            createdAt: user.createdAt
        )
    }
}

// MARK: - Request/Response DTOs

struct LoginRequest: Content {
    let username: String
}

struct UserResponse: Content {
    let id: UUID
    let username: String
    let createdAt: Date?
}
