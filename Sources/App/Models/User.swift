// Sources/App/Models/User.swift
// T004: User model for authentication and content ownership

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    // Relationships
    @Children(for: \.$owner)
    var albums: [Album]
    
    @Children(for: \.$owner)
    var photos: [Photo]
    
    @Children(for: \.$user)
    var likes: [Like]
    
    init() { }
    
    init(id: UUID? = nil, username: String) {
        self.id = id
        self.username = username
    }
}

// MARK: - Validations
extension User: Validatable {
    static func validations(_ validations: inout Validations) {
        // Username must be 3-50 characters
        validations.add("username", as: String.self, is: .count(3...50))
        // Username must contain only alphanumeric characters, hyphens, and underscores
        validations.add("username", as: String.self, is: .characterSet(.alphanumerics + .init(charactersIn: "-_")))
    }
}

// MARK: - Session Authentication
extension User: SessionAuthenticatable {
    var sessionID: UUID {
        self.id ?? UUID()
    }
}

// MARK: - Model Authenticatable (for session lookup)
extension User: ModelSessionAuthenticatable { }
