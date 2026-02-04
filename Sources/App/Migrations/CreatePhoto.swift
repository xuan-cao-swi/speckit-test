import Fluent

struct CreatePhoto: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("photos")
            .id()
            .field("album_id", .uuid, .required, .references("albums", "id", onDelete: .cascade))
            .field("file_path", .string, .required)
            .field("display_order", .int, .required)
            .field("thumbnail_path", .string)
            .field("file_size", .int, .required)
            .field("width", .int, .required)
            .field("height", .int, .required)
            .field("format", .string, .required)
            .field("added_at", .datetime)
            .unique(on: "file_path")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("photos").delete()
    }
}
