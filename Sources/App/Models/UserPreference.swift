import Fluent
import Vapor

final class UserPreference: Model, Content {
    static let schema = "user_preferences"
    
    // Singleton ID - always use the same UUID
    static let singletonId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "sort_direction")
    var sortDirection: String
    
    @Field(key: "thumbnail_size")
    var thumbnailSize: Int
    
    @Field(key: "theme")
    var theme: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = singletonId,
        sortDirection: String = "DESC",
        thumbnailSize: Int = 200,
        theme: String = "light"
    ) {
        self.id = id
        self.sortDirection = sortDirection
        self.thumbnailSize = thumbnailSize
        self.theme = theme
    }
}

// MARK: - Validations
extension UserPreference: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("sortDirection", as: String.self, is: .in("ASC", "DESC"))
        validations.add("thumbnailSize", as: Int.self, is: .range(100...500))
        validations.add("theme", as: String.self, is: .in("light", "dark"))
    }
}

// MARK: - Singleton Helper
extension UserPreference {
    static func getOrCreate(on db: Database) async throws -> UserPreference {
        if let existing = try await UserPreference.find(singletonId, on: db) {
            return existing
        }
        
        let preference = UserPreference()
        try await preference.save(on: db)
        return preference
    }
}
