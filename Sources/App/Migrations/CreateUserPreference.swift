import Fluent

struct CreateUserPreference: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_preferences")
            .id()
            .field("sort_direction", .string, .required)
            .field("thumbnail_size", .int, .required)
            .field("theme", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
        
        // Create default singleton record
        let preference = UserPreference(
            id: UserPreference.singletonId,
            sortDirection: "DESC",
            thumbnailSize: 200,
            theme: "light"
        )
        try await preference.create(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_preferences").delete()
    }
}
