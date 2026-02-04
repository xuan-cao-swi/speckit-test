import Vapor
import Fluent

// T163-T164: PreferenceController for user settings
struct PreferenceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let preferences = routes.grouped("api", "preferences")
        preferences.get(use: show)
        preferences.patch(use: update)
    }
    
    // T163: GET /api/preferences - Get user preferences (creates default if missing)
    func show(req: Request) async throws -> UserPreference {
        let preference = try await UserPreference.getOrCreate(on: req.db)
        return preference
    }
    
    // T164, T166: PATCH /api/preferences - Update user preferences with validation
    func update(req: Request) async throws -> UserPreference {
        struct UpdateRequest: Content {
            let sortDirection: String?
            let thumbnailSize: Int?
            let theme: String?
        }
        
        let input = try req.content.decode(UpdateRequest.self)
        let preference = try await UserPreference.getOrCreate(on: req.db)
        
        // T166: Validate sortDirection (ASC/DESC)
        if let sortDirection = input.sortDirection {
            guard sortDirection == "ASC" || sortDirection == "DESC" else {
                throw Abort(.badRequest, reason: "sortDirection must be 'ASC' or 'DESC'")
            }
            preference.sortDirection = sortDirection
        }
        
        // T166: Validate thumbnailSize (100-500)
        if let thumbnailSize = input.thumbnailSize {
            guard thumbnailSize >= 100 && thumbnailSize <= 500 else {
                throw Abort(.badRequest, reason: "thumbnailSize must be between 100 and 500")
            }
            preference.thumbnailSize = thumbnailSize
        }
        
        // T166: Validate theme (light/dark)
        if let theme = input.theme {
            guard theme == "light" || theme == "dark" else {
                throw Abort(.badRequest, reason: "theme must be 'light' or 'dark'")
            }
            preference.theme = theme
        }
        
        try await preference.save(on: req.db)
        return preference
    }
}
