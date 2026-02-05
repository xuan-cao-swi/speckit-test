import Fluent

struct CreateAlbum: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("albums")
            .id()
            .field("name", .string, .required)
            .field("date", .date, .required)
            .field("custom_order", .int)
            .field("cover_photo_id", .uuid)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("albums").delete()
    }
}
