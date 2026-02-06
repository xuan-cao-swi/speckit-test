// Sources/App/Controllers/LikeController.swift
// T024, T025: Like controller and DTOs for like/unlike/count endpoints

import Vapor
import Fluent

struct LikeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // Photo like routes
        let photos = api.grouped("photos")
        let photoProtected = photos.grouped(UserSessionAuthenticator())
            .grouped(UserGuardMiddleware())
        
        // Authenticated routes for photo likes
        photoProtected.post(":photoID", "like", use: likePhoto)
        photoProtected.delete(":photoID", "like", use: unlikePhoto)
        
        // Public/semi-public route for getting likes (auth optional)
        photos.grouped(UserSessionAuthenticator())
            .get(":photoID", "likes", use: getPhotoLikes)
        photos.grouped(UserSessionAuthenticator())
            .get(":photoID", "likers", use: getPhotoLikers)
        
        // Album like routes
        let albums = api.grouped("albums")
        let albumProtected = albums.grouped(UserSessionAuthenticator())
            .grouped(UserGuardMiddleware())
        
        // Authenticated routes for album likes
        albumProtected.post(":albumID", "like", use: likeAlbum)
        albumProtected.delete(":albumID", "like", use: unlikeAlbum)
        
        // Public/semi-public route for getting likes (auth optional)
        albums.grouped(UserSessionAuthenticator())
            .get(":albumID", "likes", use: getAlbumLikes)
        albums.grouped(UserSessionAuthenticator())
            .get(":albumID", "likers", use: getAlbumLikers)
    }
    
    // MARK: - Photo Like Endpoints
    
    /// POST /api/photos/:photoID/like
    @Sendable
    func likePhoto(req: Request) async throws -> LikeResponseDTO {
        let user = try req.requireUser()
        let photoId = try req.parameters.require("photoID", as: UUID.self)
        
        let like = try await LikeService.likePhoto(
            photoId: photoId,
            userId: try user.requireID(),
            on: req.db
        )
        
        let count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: req.db)
        
        return LikeResponseDTO(
            id: try like.requireID(),
            likeCount: count,
            isLikedByCurrentUser: true
        )
    }
    
    /// DELETE /api/photos/:photoID/like
    @Sendable
    func unlikePhoto(req: Request) async throws -> HTTPStatus {
        let user = try req.requireUser()
        let photoId = try req.parameters.require("photoID", as: UUID.self)
        
        try await LikeService.unlikePhoto(
            photoId: photoId,
            userId: try user.requireID(),
            on: req.db
        )
        
        return .noContent
    }
    
    /// GET /api/photos/:photoID/likes
    @Sendable
    func getPhotoLikes(req: Request) async throws -> LikeInfoResponseDTO {
        let photoId = try req.parameters.require("photoID", as: UUID.self)
        
        // Verify photo exists
        guard let photo = try await Photo.find(photoId, on: req.db) else {
            throw Abort(.notFound, reason: "Photo not found")
        }
        
        let count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: req.db)
        
        var isLikedByCurrentUser = false
        var isOwnedByCurrentUser = false
        
        if let user = req.getUser() {
            let userId = try user.requireID()
            isLikedByCurrentUser = try await LikeService.hasUserLikedPhoto(
                photoId: photoId,
                userId: userId,
                on: req.db
            )
            isOwnedByCurrentUser = photo.$owner.id == userId
        }
        
        return LikeInfoResponseDTO(
            likeCount: count,
            isLikedByCurrentUser: isLikedByCurrentUser,
            isOwnedByCurrentUser: isOwnedByCurrentUser
        )
    }
    
    /// GET /api/photos/:photoID/likers
    @Sendable
    func getPhotoLikers(req: Request) async throws -> LikersResponseDTO {
        let photoId = try req.parameters.require("photoID", as: UUID.self)
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        // Verify photo exists
        guard try await Photo.find(photoId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Photo not found")
        }
        
        let totalCount = try await LikeService.getPhotoLikeCount(photoId: photoId, on: req.db)
        let likers = try await LikeService.getPhotoLikers(photoId: photoId, limit: limit, on: req.db)
        
        return LikersResponseDTO(
            totalCount: totalCount,
            likers: likers.map { LikerInfoDTO(username: $0.username, likedAt: $0.likedAt) },
            hasMore: totalCount > likers.count
        )
    }
    
    // MARK: - Album Like Endpoints
    
    /// POST /api/albums/:albumID/like
    @Sendable
    func likeAlbum(req: Request) async throws -> LikeResponseDTO {
        let user = try req.requireUser()
        let albumId = try req.parameters.require("albumID", as: UUID.self)
        
        let like = try await LikeService.likeAlbum(
            albumId: albumId,
            userId: try user.requireID(),
            on: req.db
        )
        
        let count = try await LikeService.getAlbumLikeCount(albumId: albumId, on: req.db)
        
        return LikeResponseDTO(
            id: try like.requireID(),
            likeCount: count,
            isLikedByCurrentUser: true
        )
    }
    
    /// DELETE /api/albums/:albumID/like
    @Sendable
    func unlikeAlbum(req: Request) async throws -> HTTPStatus {
        let user = try req.requireUser()
        let albumId = try req.parameters.require("albumID", as: UUID.self)
        
        try await LikeService.unlikeAlbum(
            albumId: albumId,
            userId: try user.requireID(),
            on: req.db
        )
        
        return .noContent
    }
    
    /// GET /api/albums/:albumID/likes
    @Sendable
    func getAlbumLikes(req: Request) async throws -> LikeInfoResponseDTO {
        let albumId = try req.parameters.require("albumID", as: UUID.self)
        
        // Verify album exists
        guard let album = try await Album.find(albumId, on: req.db) else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        let count = try await LikeService.getAlbumLikeCount(albumId: albumId, on: req.db)
        
        var isLikedByCurrentUser = false
        var isOwnedByCurrentUser = false
        
        if let user = req.getUser() {
            let userId = try user.requireID()
            isLikedByCurrentUser = try await LikeService.hasUserLikedAlbum(
                albumId: albumId,
                userId: userId,
                on: req.db
            )
            isOwnedByCurrentUser = album.$owner.id == userId
        }
        
        return LikeInfoResponseDTO(
            likeCount: count,
            isLikedByCurrentUser: isLikedByCurrentUser,
            isOwnedByCurrentUser: isOwnedByCurrentUser
        )
    }
    
    /// GET /api/albums/:albumID/likers
    @Sendable
    func getAlbumLikers(req: Request) async throws -> LikersResponseDTO {
        let albumId = try req.parameters.require("albumID", as: UUID.self)
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        // Verify album exists
        guard try await Album.find(albumId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Album not found")
        }
        
        let totalCount = try await LikeService.getAlbumLikeCount(albumId: albumId, on: req.db)
        let likers = try await LikeService.getAlbumLikers(albumId: albumId, limit: limit, on: req.db)
        
        return LikersResponseDTO(
            totalCount: totalCount,
            likers: likers.map { LikerInfoDTO(username: $0.username, likedAt: $0.likedAt) },
            hasMore: totalCount > likers.count
        )
    }
}

// MARK: - Response DTOs

struct LikeResponseDTO: Content {
    let id: UUID
    let likeCount: Int
    let isLikedByCurrentUser: Bool
}

struct LikeInfoResponseDTO: Content {
    let likeCount: Int
    let isLikedByCurrentUser: Bool
    let isOwnedByCurrentUser: Bool
}

struct LikersResponseDTO: Content {
    let totalCount: Int
    let likers: [LikerInfoDTO]
    let hasMore: Bool
}

struct LikerInfoDTO: Content {
    let username: String
    let likedAt: Date
}
