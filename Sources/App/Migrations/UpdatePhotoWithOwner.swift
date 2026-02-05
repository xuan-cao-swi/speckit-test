// Sources/App/Migrations/UpdatePhotoWithOwner.swift
// T007: Migration to add ownerId to photos table

import Fluent
import Foundation

struct UpdatePhotoWithOwner: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Get the default system user (created in UpdateAlbumWithOwner migration)
        let defaultUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        
        // Add owner_id column to photos (nullable initially for migration)
        try await database.schema("photos")
            .field("owner_id", .uuid)
            .update()
        
        // Update existing photos to have the default system user as owner
        try await database.query(Photo.self)
            .set(\.$owner.$id, to: defaultUserId)
            .update()
        
        // Note: SQLite doesn't support ALTER COLUMN to add NOT NULL constraint
        // Application-level validation ensures ownerId is always set for new photos
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("photos")
            .deleteField("owner_id")
            .update()
    }
}
