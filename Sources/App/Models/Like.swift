// Sources/App/Models/Like.swift
// T020: Like model for social media likes feature

import Fluent
import Vapor

final class Like: Model, Content, @unchecked Sendable {
    static let schema = "likes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @OptionalParent(key: "photo_id")
    var photo: Photo?
    
    @OptionalParent(key: "album_id")
    var album: Album?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    /// Create a like for a photo
    init(id: UUID? = nil, userId: UUID, photoId: UUID) {
        self.id = id
        self.$user.id = userId
        self.$photo.id = photoId
        self.$album.id = nil
    }
    
    /// Create a like for an album
    init(id: UUID? = nil, userId: UUID, albumId: UUID) {
        self.id = id
        self.$user.id = userId
        self.$photo.id = nil
        self.$album.id = albumId
    }
}

// MARK: - Business Logic Validation
extension Like {
    /// Validates that exactly one of photoId or albumId is set (XOR constraint)
    func validateXOR() throws {
        let hasPhoto = $photo.id != nil
        let hasAlbum = $album.id != nil
        
        guard hasPhoto != hasAlbum else {
            throw Abort(.badRequest, reason: "Like must target exactly one photo OR one album, not both or neither")
        }
    }
}

// MARK: - Model Middleware for XOR Validation
struct LikeXORMiddleware: AsyncModelMiddleware {
    func create(model: Like, on db: Database, next: AnyAsyncModelResponder) async throws {
        try model.validateXOR()
        try await next.create(model, on: db)
    }
    
    func update(model: Like, on db: Database, next: AnyAsyncModelResponder) async throws {
        try model.validateXOR()
        try await next.update(model, on: db)
    }
}
