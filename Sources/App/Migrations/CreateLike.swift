// Sources/App/Migrations/CreateLike.swift
// T021: Migration to create likes table with XOR constraint and unique indexes

import Fluent
import SQLKit

struct CreateLike: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("likes")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("photo_id", .uuid, .references("photos", "id", onDelete: .cascade))
            .field("album_id", .uuid, .references("albums", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            // Unique constraints for (user_id, photo_id) and (user_id, album_id)
            .unique(on: "user_id", "photo_id")
            .unique(on: "user_id", "album_id")
            .create()
        
        // Add indexes for efficient counting
        // Note: SQLite creates indexes automatically for foreign keys,
        // but we add explicit indexes for counting queries
        if let sqlDb = database as? (any SQLDatabase) {
            // Index for counting photo likes
            try await sqlDb.raw("CREATE INDEX IF NOT EXISTS idx_likes_photo_id ON likes(photo_id)").run()
            // Index for counting album likes  
            try await sqlDb.raw("CREATE INDEX IF NOT EXISTS idx_likes_album_id ON likes(album_id)").run()
            // Index for user's likes lookup
            try await sqlDb.raw("CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id)").run()
            
            // XOR check constraint (exactly one of photo_id or album_id must be set)
            // Note: SQLite doesn't support CHECK constraints added after table creation,
            // so this is enforced at the application level via LikeXORMiddleware
        }
    }
    
    func revert(on database: Database) async throws {
        if let sqlDb = database as? (any SQLDatabase) {
            try await sqlDb.raw("DROP INDEX IF EXISTS idx_likes_photo_id").run()
            try await sqlDb.raw("DROP INDEX IF EXISTS idx_likes_album_id").run()
            try await sqlDb.raw("DROP INDEX IF EXISTS idx_likes_user_id").run()
        }
        try await database.schema("likes").delete()
    }
}
