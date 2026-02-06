// Tests/AppTests/Services/LikeServiceTests.swift
// T018: Unit tests for LikeService (TDD - write first, ensure they fail)

@testable import PhotoAlbumOrganizer
import XCTVapor

final class LikeServiceTests: XCTestCase {
    var app: Application!
    var user1: User!
    var user2: User!
    var album: Album!
    var photo: Photo!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
        
        // Create two users (user1 owns content, user2 can like it)
        user1 = User(username: "owner")
        try await user1.save(on: app.db)
        
        user2 = User(username: "liker")
        try await user2.save(on: app.db)
        
        let user1Id = try user1.requireID()
        
        // Create album owned by user1
        album = Album(name: "Test Album", date: Date(), ownerId: user1Id)
        try await album.save(on: app.db)
        
        // Create photo owned by user1
        photo = Photo(
            albumId: try album.requireID(),
            filePath: "/test/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG",
            ownerId: user1Id
        )
        try await photo.save(on: app.db)
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
        user1 = nil
        user2 = nil
        album = nil
        photo = nil
    }
    
    // MARK: - Photo Like Tests
    
    func testLikePhoto() async throws {
        let like = try await LikeService.likePhoto(
            photoId: try photo.requireID(),
            userId: try user2.requireID(),
            on: app.db
        )
        
        XCTAssertNotNil(like.id)
        XCTAssertEqual(like.$user.id, user2.id)
        XCTAssertEqual(like.$photo.id, photo.id)
    }
    
    func testLikePhotoIsIdempotent() async throws {
        let userId = try user2.requireID()
        let photoId = try photo.requireID()
        
        // First like
        let like1 = try await LikeService.likePhoto(photoId: photoId, userId: userId, on: app.db)
        
        // Second like of same photo - should return same like (idempotent)
        let like2 = try await LikeService.likePhoto(photoId: photoId, userId: userId, on: app.db)
        
        XCTAssertEqual(like1.id, like2.id, "Liking same photo twice should return same like")
    }
    
    func testLikePhotoPreventsSelfLike() async throws {
        // User1 (owner) tries to like their own photo
        do {
            _ = try await LikeService.likePhoto(
                photoId: try photo.requireID(),
                userId: try user1.requireID(),  // Owner trying to like
                on: app.db
            )
            XCTFail("Should not allow owner to like their own photo")
        } catch let error as Abort {
            XCTAssertEqual(error.status, .badRequest)
            XCTAssertTrue(error.reason.contains("own content") || error.reason.contains("own photo"))
        }
    }
    
    func testUnlikePhoto() async throws {
        let userId = try user2.requireID()
        let photoId = try photo.requireID()
        
        // First like the photo
        _ = try await LikeService.likePhoto(photoId: photoId, userId: userId, on: app.db)
        
        // Verify like exists
        var count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: app.db)
        XCTAssertEqual(count, 1)
        
        // Unlike the photo
        try await LikeService.unlikePhoto(photoId: photoId, userId: userId, on: app.db)
        
        // Verify like is gone
        count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: app.db)
        XCTAssertEqual(count, 0)
    }
    
    func testUnlikePhotoIsIdempotent() async throws {
        let userId = try user2.requireID()
        let photoId = try photo.requireID()
        
        // Unlike without having liked (should not throw)
        do {
            try await LikeService.unlikePhoto(photoId: photoId, userId: userId, on: app.db)
            // Success - no exception thrown
        } catch {
            XCTFail("Unlike without prior like should not throw: \(error)")
        }
        
        // Like then unlike twice
        _ = try await LikeService.likePhoto(photoId: photoId, userId: userId, on: app.db)
        try await LikeService.unlikePhoto(photoId: photoId, userId: userId, on: app.db)
        
        // Second unlike should not throw
        do {
            try await LikeService.unlikePhoto(photoId: photoId, userId: userId, on: app.db)
            // Success - no exception thrown
        } catch {
            XCTFail("Second unlike should not throw: \(error)")
        }
    }
    
    func testGetPhotoLikeCount() async throws {
        let photoId = try photo.requireID()
        
        // Initially 0
        var count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: app.db)
        XCTAssertEqual(count, 0)
        
        // Add a like
        _ = try await LikeService.likePhoto(photoId: photoId, userId: try user2.requireID(), on: app.db)
        
        count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: app.db)
        XCTAssertEqual(count, 1)
        
        // Add another user
        let user3 = User(username: "liker3")
        try await user3.save(on: app.db)
        _ = try await LikeService.likePhoto(photoId: photoId, userId: try user3.requireID(), on: app.db)
        
        count = try await LikeService.getPhotoLikeCount(photoId: photoId, on: app.db)
        XCTAssertEqual(count, 2)
    }
    
    func testHasUserLikedPhoto() async throws {
        let userId = try user2.requireID()
        let photoId = try photo.requireID()
        
        // Initially false
        var hasLiked = try await LikeService.hasUserLikedPhoto(photoId: photoId, userId: userId, on: app.db)
        XCTAssertFalse(hasLiked)
        
        // After liking
        _ = try await LikeService.likePhoto(photoId: photoId, userId: userId, on: app.db)
        hasLiked = try await LikeService.hasUserLikedPhoto(photoId: photoId, userId: userId, on: app.db)
        XCTAssertTrue(hasLiked)
        
        // After unliking
        try await LikeService.unlikePhoto(photoId: photoId, userId: userId, on: app.db)
        hasLiked = try await LikeService.hasUserLikedPhoto(photoId: photoId, userId: userId, on: app.db)
        XCTAssertFalse(hasLiked)
    }
    
    // MARK: - Album Like Tests
    
    func testLikeAlbum() async throws {
        let like = try await LikeService.likeAlbum(
            albumId: try album.requireID(),
            userId: try user2.requireID(),
            on: app.db
        )
        
        XCTAssertNotNil(like.id)
        XCTAssertEqual(like.$user.id, user2.id)
        XCTAssertEqual(like.$album.id, album.id)
    }
    
    func testLikeAlbumIsIdempotent() async throws {
        let userId = try user2.requireID()
        let albumId = try album.requireID()
        
        // First like
        let like1 = try await LikeService.likeAlbum(albumId: albumId, userId: userId, on: app.db)
        
        // Second like of same album - should return same like (idempotent)
        let like2 = try await LikeService.likeAlbum(albumId: albumId, userId: userId, on: app.db)
        
        XCTAssertEqual(like1.id, like2.id, "Liking same album twice should return same like")
    }
    
    func testLikeAlbumPreventsSelfLike() async throws {
        // User1 (owner) tries to like their own album
        do {
            _ = try await LikeService.likeAlbum(
                albumId: try album.requireID(),
                userId: try user1.requireID(),  // Owner trying to like
                on: app.db
            )
            XCTFail("Should not allow owner to like their own album")
        } catch let error as Abort {
            XCTAssertEqual(error.status, .badRequest)
            XCTAssertTrue(error.reason.contains("own content") || error.reason.contains("own album"))
        }
    }
    
    func testUnlikeAlbum() async throws {
        let userId = try user2.requireID()
        let albumId = try album.requireID()
        
        // First like the album
        _ = try await LikeService.likeAlbum(albumId: albumId, userId: userId, on: app.db)
        
        // Verify like exists
        var count = try await LikeService.getAlbumLikeCount(albumId: albumId, on: app.db)
        XCTAssertEqual(count, 1)
        
        // Unlike the album
        try await LikeService.unlikeAlbum(albumId: albumId, userId: userId, on: app.db)
        
        // Verify like is gone
        count = try await LikeService.getAlbumLikeCount(albumId: albumId, on: app.db)
        XCTAssertEqual(count, 0)
    }
    
    func testUnlikeAlbumIsIdempotent() async throws {
        let userId = try user2.requireID()
        let albumId = try album.requireID()
        
        // Unlike without having liked (should not throw)
        do {
            try await LikeService.unlikeAlbum(albumId: albumId, userId: userId, on: app.db)
            // Success - no exception thrown
        } catch {
            XCTFail("Unlike without prior like should not throw: \(error)")
        }
    }
    
    func testGetAlbumLikeCount() async throws {
        let albumId = try album.requireID()
        
        // Initially 0
        var count = try await LikeService.getAlbumLikeCount(albumId: albumId, on: app.db)
        XCTAssertEqual(count, 0)
        
        // Add a like
        _ = try await LikeService.likeAlbum(albumId: albumId, userId: try user2.requireID(), on: app.db)
        
        count = try await LikeService.getAlbumLikeCount(albumId: albumId, on: app.db)
        XCTAssertEqual(count, 1)
    }
    
    func testHasUserLikedAlbum() async throws {
        let userId = try user2.requireID()
        let albumId = try album.requireID()
        
        // Initially false
        var hasLiked = try await LikeService.hasUserLikedAlbum(albumId: albumId, userId: userId, on: app.db)
        XCTAssertFalse(hasLiked)
        
        // After liking
        _ = try await LikeService.likeAlbum(albumId: albumId, userId: userId, on: app.db)
        hasLiked = try await LikeService.hasUserLikedAlbum(albumId: albumId, userId: userId, on: app.db)
        XCTAssertTrue(hasLiked)
        
        // After unliking
        try await LikeService.unlikeAlbum(albumId: albumId, userId: userId, on: app.db)
        hasLiked = try await LikeService.hasUserLikedAlbum(albumId: albumId, userId: userId, on: app.db)
        XCTAssertFalse(hasLiked)
    }
    
    // MARK: - Liker List Tests (User Story 4)
    
    func testGetPhotoLikers() async throws {
        let photoId = try photo.requireID()
        
        // Add some likers
        let user3 = User(username: "liker3")
        try await user3.save(on: app.db)
        
        _ = try await LikeService.likePhoto(photoId: photoId, userId: try user2.requireID(), on: app.db)
        _ = try await LikeService.likePhoto(photoId: photoId, userId: try user3.requireID(), on: app.db)
        
        let likers = try await LikeService.getPhotoLikers(photoId: photoId, limit: 10, on: app.db)
        
        XCTAssertEqual(likers.count, 2)
        let usernames = likers.map { $0.username }
        XCTAssertTrue(usernames.contains("liker"))
        XCTAssertTrue(usernames.contains("liker3"))
    }
    
    func testGetPhotoLikersWithLimit() async throws {
        let photoId = try photo.requireID()
        
        // Add multiple likers
        for i in 3...7 {
            let user = User(username: "liker\(i)")
            try await user.save(on: app.db)
            _ = try await LikeService.likePhoto(photoId: photoId, userId: try user.requireID(), on: app.db)
        }
        
        // Get with limit
        let likers = try await LikeService.getPhotoLikers(photoId: photoId, limit: 3, on: app.db)
        XCTAssertEqual(likers.count, 3)
    }
    
    func testGetAlbumLikers() async throws {
        let albumId = try album.requireID()
        
        // Add some likers
        let user3 = User(username: "albumliker")
        try await user3.save(on: app.db)
        
        _ = try await LikeService.likeAlbum(albumId: albumId, userId: try user2.requireID(), on: app.db)
        _ = try await LikeService.likeAlbum(albumId: albumId, userId: try user3.requireID(), on: app.db)
        
        let likers = try await LikeService.getAlbumLikers(albumId: albumId, limit: 10, on: app.db)
        
        XCTAssertEqual(likers.count, 2)
    }
}
