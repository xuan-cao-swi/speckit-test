// Sources/App/Migrations/CreateUser.swift
// T005: Migration to create users table

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "username")  // Username must be unique
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
