import Vapor
import Fluent

struct AlbumController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let albums = routes.grouped("api", "albums")
        albums.get(use: index)
        albums.get(":albumID", use: show)
    }
    
    // T036: GET /api/albums - List all albums sorted by date
    func index(req: Request) async throws -> [Album] {
        // Get user preferences for sort direction
        let preference = try await UserPreference.getOrCreate(on: req.db)
        
        // Query albums
        let query = Album.query(on: req.db)
        
        // Sort by custom_order if available, otherwise by date
        if preference.sortDirection == "DESC" {
            query.sort(\.$date, .descending)
        } else {
            query.sort(\.$date, .ascending)
        }
        
        // Load photos relationship to compute photoCount
        let albums = try await query.with(\.$photos).all()
        
        return albums
    }
    
    // T037: GET /api/albums/:id - Get album details
    func show(req: Request) async throws -> Album {
        guard let album = try await Album.find(req.parameters.get("albumID"), on: req.db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        // Load photos relationship
        try await album.$photos.load(on: req.db)
        
        return album
    }
}
