import Vapor
import Fluent

struct PhotoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let albumPhotos = routes.grouped("api", "albums", ":albumID", "photos")
        albumPhotos.get(use: index)
        albumPhotos.post(use: create)
        
        let photos = routes.grouped("api", "photos")
        photos.delete(":photoID", use: delete)
        photos.get(":photoID", "thumbnail", use: thumbnail)
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
    
    // T094: POST /api/albums/:albumID/photos - Add photos to album
    func create(req: Request) async throws -> [Photo] {
        struct AddPhotosRequest: Content {
            let filePaths: [String]
        }
        
        guard let albumID = req.parameters.get("albumID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid album ID")
        }
        
        guard let album = try await Album.find(albumID, on: req.db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        let input = try req.content.decode(AddPhotosRequest.self)
        
        // Get current max displayOrder
        let maxOrder = try await Photo.query(on: req.db)
            .filter(\.$album.$id == albumID)
            .sort(\.$displayOrder, .descending)
            .first()?.displayOrder ?? -1
        
        var photos: [Photo] = []
        let validationService = FileValidationService()
        let thumbnailService = ThumbnailService(publicDirectory: req.application.directory.publicDirectory)
        
        // Process each file path
        for (index, filePath) in input.filePaths.enumerated() {
            do {
                // Validate file exists and is valid image
                try validationService.validateImageFile(path: filePath)
                
                // Get metadata
                let metadata = try validationService.getImageMetadata(path: filePath)
                
                // Get dimensions from ImageIO
                let dimensions = thumbnailService.getImageDimensions(path: filePath) ?? (800, 600)
                
                let photo = Photo(
                    albumId: albumID,
                    filePath: filePath,
                    displayOrder: maxOrder + index + 1,
                    fileSize: metadata.fileSize,
                    width: dimensions.width,
                    height: dimensions.height,
                    format: metadata.format
                )
                
                try await photo.save(on: req.db)
                photos.append(photo)
                
                // Generate thumbnail in background (optional)
                _ = try? thumbnailService.generateThumbnail(sourcePath: filePath, photoId: try photo.requireID())
            } catch {
                // Skip invalid files, continue with others
                req.logger.error("Failed to add photo \(filePath): \(error)")
            }
        }
        
        return photos
    }
    
    // T095: DELETE /api/photos/:photoID - Remove photo
    func delete(req: Request) async throws -> Response {
        guard let photo = try await Photo.find(req.parameters.get("photoID"), on: req.db) else {
            throw Abort(.notFound, reason: "Photo not found")
        }
        
        try await photo.delete(on: req.db)
        
        return Response(status: .noContent)
    }
    
    // T096: GET /api/photos/:photoID/thumbnail - Serve thumbnail
    func thumbnail(req: Request) async throws -> Response {
        guard let photoID = req.parameters.get("photoID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid photo ID")
        }
        
        guard let photo = try await Photo.find(photoID, on: req.db) else {
            throw Abort(.notFound, reason: "Photo not found")
        }
        
        let thumbnailService = ThumbnailService(publicDirectory: req.application.directory.publicDirectory)
        
        // Check for cached thumbnail
        if let cachedPath = thumbnailService.getCachedThumbnail(photoId: photoID) {
            return req.fileio.streamFile(at: cachedPath)
        }
        
        // Generate thumbnail on demand
        do {
            let thumbnailPath = try thumbnailService.generateThumbnail(sourcePath: photo.filePath, photoId: photoID)
            return req.fileio.streamFile(at: thumbnailPath)
        } catch {
            // Fallback: try to serve original image
            return req.fileio.streamFile(at: photo.filePath)
        }
    }
}
