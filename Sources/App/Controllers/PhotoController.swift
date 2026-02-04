import Vapor
import Fluent

struct PhotoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let photos = routes.grouped("api", "albums", ":albumID", "photos")
        photos.get(use: index)
    }
    
    // T038: GET /api/albums/:albumID/photos - List photos in album sorted by displayOrder
    func index(req: Request) async throws -> [Photo] {
        guard let albumID = req.parameters.get("albumID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid album ID")
        }
        
        // Verify album exists
        guard let _ = try await Album.find(albumID, on: req.db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        // Get photos sorted by displayOrder
        let photos = try await Photo.query(on: req.db)
            .filter(\.$album.$id == albumID)
            .sort(\.$displayOrder, .ascending)
            .all()
        
        return photos
    }
}
