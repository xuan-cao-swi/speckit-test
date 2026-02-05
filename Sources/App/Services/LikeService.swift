// Sources/App/Services/LikeService.swift
// T023: Service layer for like operations

import Fluent
import Vapor

/// Service for managing likes on photos and albums
enum LikeService {
    
    // MARK: - Photo Likes
    
    /// Like a photo (idempotent - returns existing like if already liked)
    /// - Parameters:
    ///   - photoId: The ID of the photo to like
    ///   - userId: The ID of the user liking the photo
    ///   - db: Database connection
    /// - Returns: The created or existing Like
    /// - Throws: Abort(.badRequest) if user is the owner, Abort(.notFound) if photo doesn't exist
    static func likePhoto(photoId: UUID, userId: UUID, on db: Database) async throws -> Like {
        // Verify photo exists and check ownership
        guard let photo = try await Photo.find(photoId, on: db) else {
            throw Abort(.notFound, reason: "Photo not found")
        }
        
        // Prevent self-like
        if photo.$owner.id == userId {
            throw Abort(.badRequest, reason: "Cannot like your own content")
        }
        
        // Check if already liked (idempotent)
        if let existingLike = try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$photo.$id == photoId)
            .first() {
            return existingLike
        }
        
        // Create new like
        let like = Like(userId: userId, photoId: photoId)
        try await like.save(on: db)
        return like
    }
    
    /// Unlike a photo (idempotent - no error if not liked)
    /// - Parameters:
    ///   - photoId: The ID of the photo to unlike
    ///   - userId: The ID of the user unliking the photo
    ///   - db: Database connection
    static func unlikePhoto(photoId: UUID, userId: UUID, on db: Database) async throws {
        try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$photo.$id == photoId)
            .delete()
    }
    
    /// Get the like count for a photo
    /// - Parameters:
    ///   - photoId: The ID of the photo
    ///   - db: Database connection
    /// - Returns: Number of likes
    static func getPhotoLikeCount(photoId: UUID, on db: Database) async throws -> Int {
        try await Like.query(on: db)
            .filter(\.$photo.$id == photoId)
            .count()
    }
    
    /// Check if a user has liked a photo
    /// - Parameters:
    ///   - photoId: The ID of the photo
    ///   - userId: The ID of the user
    ///   - db: Database connection
    /// - Returns: True if the user has liked the photo
    static func hasUserLikedPhoto(photoId: UUID, userId: UUID, on db: Database) async throws -> Bool {
        let count = try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$photo.$id == photoId)
            .count()
        return count > 0
    }
    
    /// Get list of users who liked a photo
    /// - Parameters:
    ///   - photoId: The ID of the photo
    ///   - limit: Maximum number of likers to return
    ///   - db: Database connection
    /// - Returns: Array of LikerInfo with username and timestamp
    static func getPhotoLikers(photoId: UUID, limit: Int, on db: Database) async throws -> [LikerDTO] {
        let likes = try await Like.query(on: db)
            .filter(\.$photo.$id == photoId)
            .sort(\.$createdAt, .descending)
            .with(\.$user)
            .limit(limit)
            .all()
        
        return likes.compactMap { like in
            guard let createdAt = like.createdAt else { return nil }
            return LikerDTO(username: like.user.username, likedAt: createdAt)
        }
    }
    
    // MARK: - Album Likes
    
    /// Like an album (idempotent - returns existing like if already liked)
    /// - Parameters:
    ///   - albumId: The ID of the album to like
    ///   - userId: The ID of the user liking the album
    ///   - db: Database connection
    /// - Returns: The created or existing Like
    /// - Throws: Abort(.badRequest) if user is the owner, Abort(.notFound) if album doesn't exist
    static func likeAlbum(albumId: UUID, userId: UUID, on db: Database) async throws -> Like {
        // Verify album exists and check ownership
        guard let album = try await Album.find(albumId, on: db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        // Prevent self-like
        if album.$owner.id == userId {
            throw Abort(.badRequest, reason: "Cannot like your own content")
        }
        
        // Check if already liked (idempotent)
        if let existingLike = try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$album.$id == albumId)
            .first() {
            return existingLike
        }
        
        // Create new like
        let like = Like(userId: userId, albumId: albumId)
        try await like.save(on: db)
        return like
    }
    
    /// Unlike an album (idempotent - no error if not liked)
    /// - Parameters:
    ///   - albumId: The ID of the album to unlike
    ///   - userId: The ID of the user unliking the album
    ///   - db: Database connection
    static func unlikeAlbum(albumId: UUID, userId: UUID, on db: Database) async throws {
        try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$album.$id == albumId)
            .delete()
    }
    
    /// Get the like count for an album
    /// - Parameters:
    ///   - albumId: The ID of the album
    ///   - db: Database connection
    /// - Returns: Number of likes
    static func getAlbumLikeCount(albumId: UUID, on db: Database) async throws -> Int {
        try await Like.query(on: db)
            .filter(\.$album.$id == albumId)
            .count()
    }
    
    /// Check if a user has liked an album
    /// - Parameters:
    ///   - albumId: The ID of the album
    ///   - userId: The ID of the user
    ///   - db: Database connection
    /// - Returns: True if the user has liked the album
    static func hasUserLikedAlbum(albumId: UUID, userId: UUID, on db: Database) async throws -> Bool {
        let count = try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$album.$id == albumId)
            .count()
        return count > 0
    }
    
    /// Get list of users who liked an album
    /// - Parameters:
    ///   - albumId: The ID of the album
    ///   - limit: Maximum number of likers to return
    ///   - db: Database connection
    /// - Returns: Array of LikerInfo with username and timestamp
    static func getAlbumLikers(albumId: UUID, limit: Int, on db: Database) async throws -> [LikerDTO] {
        let likes = try await Like.query(on: db)
            .filter(\.$album.$id == albumId)
            .sort(\.$createdAt, .descending)
            .with(\.$user)
            .limit(limit)
            .all()
        
        return likes.compactMap { like in
            guard let createdAt = like.createdAt else { return nil }
            return LikerDTO(username: like.user.username, likedAt: createdAt)
        }
    }
}

// MARK: - DTOs

struct LikerDTO {
    let username: String
    let likedAt: Date
}
