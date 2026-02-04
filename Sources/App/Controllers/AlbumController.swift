import Vapor
import Fluent

struct AlbumController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let albums = routes.grouped("api", "albums")
        albums.get(use: index)
        albums.post(use: create)
        albums.patch("reorder", use: reorder) // T122: Reorder route
        albums.get(":albumID", use: show)
        albums.patch(":albumID", use: update)
        albums.delete(":albumID", use: delete)
    }
    
    // T036, T121: GET /api/albums - List all albums sorted by date or custom order
    func index(req: Request) async throws -> [Album] {
        // Get user preferences for sort direction
        let preference = try await UserPreference.getOrCreate(on: req.db)
        
        // Check for sort query parameter
        let sortParam = req.query[String.self, at: "sort"]
        
        // Query albums
        let query = Album.query(on: req.db)
        
        // Sort by custom_order if requested, otherwise by date
        if sortParam == "custom_order" {
            query.sort(\.$customOrder, .ascending)
        } else if preference.sortDirection == "DESC" {
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
    
    // T062: POST /api/albums - Create new album
    func create(req: Request) async throws -> Album {
        struct CreateAlbumRequest: Content {
            let name: String
            let date: String
        }
        
        let input = try req.content.decode(CreateAlbumRequest.self)
        
        // Validate name
        guard !input.name.isEmpty && input.name.count <= 255 else {
            throw Abort(.badRequest, reason: "Album name must be between 1 and 255 characters")
        }
        
        // Parse date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        guard let date = dateFormatter.date(from: input.date) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use YYYY-MM-DD")
        }
        
        let album = Album(name: input.name, date: date)
        try await album.save(on: req.db)
        
        // Load photos relationship for response
        try await album.$photos.load(on: req.db)
        
        return album
    }
    
    // T063: PATCH /api/albums/:id - Update album
    func update(req: Request) async throws -> Album {
        struct UpdateAlbumRequest: Content {
            let name: String?
            let date: String?
            let coverPhotoId: UUID?
        }
        
        guard let album = try await Album.find(req.parameters.get("albumID"), on: req.db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        let input = try req.content.decode(UpdateAlbumRequest.self)
        
        if let name = input.name {
            guard !name.isEmpty && name.count <= 255 else {
                throw Abort(.badRequest, reason: "Album name must be between 1 and 255 characters")
            }
            album.name = name
        }
        
        if let dateString = input.date {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            guard let date = dateFormatter.date(from: dateString) else {
                throw Abort(.badRequest, reason: "Invalid date format. Use YYYY-MM-DD")
            }
            album.date = date
        }
        
        if let coverPhotoId = input.coverPhotoId {
            album.coverPhotoId = coverPhotoId
        }
        
        try await album.save(on: req.db)
        
        // Load photos relationship for response
        try await album.$photos.load(on: req.db)
        
        return album
    }
    
    // T064: DELETE /api/albums/:id - Delete album
    func delete(req: Request) async throws -> Response {
        guard let album = try await Album.find(req.parameters.get("albumID"), on: req.db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        try await album.delete(on: req.db)
        
        return Response(status: .noContent)
    }
    
    // T119-T120: PATCH /api/albums/reorder - Batch update custom order with transaction
    func reorder(req: Request) async throws -> Response {
        struct ReorderRequest: Content {
            struct AlbumOrder: Content {
                let id: UUID
                let customOrder: Int
            }
            let updates: [AlbumOrder]
        }
        
        let input = try req.content.decode(ReorderRequest.self)
        
        // Use transaction to ensure atomicity
        try await req.db.transaction { database in
            for update in input.updates {
                guard let album = try await Album.find(update.id, on: database) else {
                    throw Abort(.notFound, reason: "Album with ID \(update.id) not found")
                }
                
                album.customOrder = update.customOrder
                try await album.save(on: database)
            }
        }
        
        return Response(status: .ok)
    }
}
