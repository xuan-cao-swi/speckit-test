// Tests/AppTests/Models/LikeTests.swift
// T017: Unit tests for Like model validation (TDD - write first, ensure they fail)

@testable import PhotoAlbumOrganizer
import XCTVapor
import Fluent

final class LikeTests: XCTestCase {
    var app: Application!
    var testUser: User!
    var testAlbum: Album!
    var testPhoto: Photo!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
        
        // Create test user
        testUser = User(username: "liketester")
        try await testUser.save(on: app.db)
        let userId = try testUser.requireID()
        
        // Create test album
        testAlbum = Album(name: "Test Album", date: Date(), ownerId: userId)
        try await testAlbum.save(on: app.db)
        
        // Create test photo
        testPhoto = Photo(
            albumId: try testAlbum.requireID(),
            filePath: "/test/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG",
            ownerId: userId
        )
        try await testPhoto.save(on: app.db)
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
        testUser = nil
        testAlbum = nil
        testPhoto = nil
    }
    
    // MARK: - Photo Like Tests
    
    func testLikePhotoCreation() async throws {
        let like = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        try await like.save(on: app.db)
        
        XCTAssertNotNil(like.id)
        XCTAssertEqual(like.$user.id, testUser.id)
        XCTAssertEqual(like.$photo.id, testPhoto.id)
        XCTAssertNil(like.$album.id)
        XCTAssertNotNil(like.createdAt)
    }
    
    // MARK: - Album Like Tests
    
    func testLikeAlbumCreation() async throws {
        let like = Like(userId: try testUser.requireID(), albumId: try testAlbum.requireID())
        try await like.save(on: app.db)
        
        XCTAssertNotNil(like.id)
        XCTAssertEqual(like.$user.id, testUser.id)
        XCTAssertNil(like.$photo.id)
        XCTAssertEqual(like.$album.id, testAlbum.id)
        XCTAssertNotNil(like.createdAt)
    }
    
    // MARK: - XOR Constraint Tests
    
    func testLikeXORValidation() async throws {
        // Test that XOR validation works - like must have exactly one target
        let like = Like()
        like.$user.id = try testUser.requireID()
        like.$photo.id = try testPhoto.requireID()
        like.$album.id = try testAlbum.requireID()  // Both set - invalid!
        
        do {
            try like.validateXOR()
            XCTFail("Should reject like with both photo and album set")
        } catch {
            // Expected
            XCTAssertTrue(true)
        }
    }
    
    func testLikeXORValidationNeitherSet() async throws {
        let like = Like()
        like.$user.id = try testUser.requireID()
        // Neither photo nor album set - invalid!
        
        do {
            try like.validateXOR()
            XCTFail("Should reject like with neither photo nor album set")
        } catch {
            // Expected
            XCTAssertTrue(true)
        }
    }
    
    func testLikeXORValidationPhotoOnly() async throws {
        let like = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        
        // Should not throw
        XCTAssertNoThrow(try like.validateXOR())
    }
    
    func testLikeXORValidationAlbumOnly() async throws {
        let like = Like(userId: try testUser.requireID(), albumId: try testAlbum.requireID())
        
        // Should not throw
        XCTAssertNoThrow(try like.validateXOR())
    }
    
    // MARK: - Relationship Tests
    
    func testLikeUserRelationship() async throws {
        let like = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        try await like.save(on: app.db)
        
        // Load user relationship
        try await like.$user.load(on: app.db)
        XCTAssertEqual(like.user.username, "liketester")
    }
    
    func testLikePhotoRelationship() async throws {
        let like = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        try await like.save(on: app.db)
        
        // Load photo relationship
        try await like.$photo.load(on: app.db)
        XCTAssertNotNil(like.photo)
        XCTAssertEqual(like.photo?.filePath, "/test/photo.jpg")
    }
    
    func testLikeAlbumRelationship() async throws {
        let like = Like(userId: try testUser.requireID(), albumId: try testAlbum.requireID())
        try await like.save(on: app.db)
        
        // Load album relationship
        try await like.$album.load(on: app.db)
        XCTAssertNotNil(like.album)
        XCTAssertEqual(like.album?.name, "Test Album")
    }
    
    // MARK: - Uniqueness Tests
    
    func testLikeUniquenessForPhoto() async throws {
        // First like
        let like1 = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        try await like1.save(on: app.db)
        
        // Second like for same photo by same user - should fail with unique constraint
        let like2 = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        
        do {
            try await like2.save(on: app.db)
            XCTFail("Should not allow duplicate likes for same photo by same user")
        } catch {
            // Expected: unique constraint violation
            XCTAssertTrue(true)
        }
    }
    
    func testLikeUniquenessForAlbum() async throws {
        // First like
        let like1 = Like(userId: try testUser.requireID(), albumId: try testAlbum.requireID())
        try await like1.save(on: app.db)
        
        // Second like for same album by same user - should fail with unique constraint
        let like2 = Like(userId: try testUser.requireID(), albumId: try testAlbum.requireID())
        
        do {
            try await like2.save(on: app.db)
            XCTFail("Should not allow duplicate likes for same album by same user")
        } catch {
            // Expected: unique constraint violation
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Cascade Delete Tests
    
    func testLikeDeletedWhenPhotoDeleted() async throws {
        let like = Like(userId: try testUser.requireID(), photoId: try testPhoto.requireID())
        try await like.save(on: app.db)
        let likeId = try like.requireID()
        
        // Delete the photo
        try await testPhoto.delete(on: app.db)
        
        // Like should be gone (cascade delete)
        let foundLike = try await Like.find(likeId, on: app.db)
        XCTAssertNil(foundLike, "Like should be deleted when photo is deleted")
    }
    
    func testLikeDeletedWhenAlbumDeleted() async throws {
        let like = Like(userId: try testUser.requireID(), albumId: try testAlbum.requireID())
        try await like.save(on: app.db)
        let likeId = try like.requireID()
        
        // Delete photos first (due to foreign key constraint)
        let albumId = try testAlbum.requireID()
        try await Photo.query(on: app.db)
            .filter(\.$album.$id == albumId)
            .delete()
        
        // Delete the album
        try await testAlbum.delete(on: app.db)
        
        // Like should be gone (cascade delete)
        let foundLike = try await Like.find(likeId, on: app.db)
        XCTAssertNil(foundLike, "Like should be deleted when album is deleted")
    }
    
    func testLikeDeletedWhenUserDeleted() async throws {
        // Create a second user to like our test photo
        let user2 = User(username: "liker2")
        try await user2.save(on: app.db)
        let user2Id = try user2.requireID()
        
        let like = Like(userId: user2Id, photoId: try testPhoto.requireID())
        try await like.save(on: app.db)
        let likeId = try like.requireID()
        
        // Delete the user
        try await user2.delete(on: app.db)
        
        // Like should be gone (cascade delete)
        let foundLike = try await Like.find(likeId, on: app.db)
        XCTAssertNil(foundLike, "Like should be deleted when user is deleted")
    }
}
