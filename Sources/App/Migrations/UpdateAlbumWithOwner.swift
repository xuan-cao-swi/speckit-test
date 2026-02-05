// Sources/App/Migrations/UpdateAlbumWithOwner.swift
// T006: Migration to add ownerId to albums table

import Fluent
import Foundation

struct UpdateAlbumWithOwner: AsyncMigration {
    func prepare(on database: Database) async throws {
        // First, create a default system user if none exists
        // This handles existing albums that need an owner
        let defaultUser = User(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001"), username: "system")
        
        // Check if system user exists, create if not
        if try await User.find(defaultUser.id, on: database) == nil {
            try await defaultUser.save(on: database)
        }
        
        // Add owner_id column to albums (nullable initially for migration)
        try await database.schema("albums")
            .field("owner_id", .uuid)
            .update()
        
        // Update existing albums to have the default system user as owner
        try await database.query(Album.self)
            .set(\.$owner.$id, to: defaultUser.id!)
            .update()
        
        // Now make the column required and add foreign key
        // Note: SQLite doesn't support ALTER COLUMN, so we rely on application-level enforcement
        // For production, consider a more robust migration with table recreation
    }
    
    func revert(on database: Database) async throws {
        // SQLite doesn't support dropping columns easily
        // For a full revert, you'd need to recreate the table
        // This is a simplified revert that handles the constraint removal
        try await database.schema("albums")
            .deleteField("owner_id")
            .update()
    }
}
