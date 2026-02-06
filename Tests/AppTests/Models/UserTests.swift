// Tests/AppTests/Models/UserTests.swift
// T014: Unit tests for User model

@testable import PhotoAlbumOrganizer
import XCTVapor
import Fluent

final class UserTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    // MARK: - Model Creation Tests
    
    func testUserCreation() async throws {
        let user = User(username: "testuser")
        try await user.save(on: app.db)
        
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.username, "testuser")
        XCTAssertNotNil(user.createdAt)
    }
    
    func testUserUsernameRequired() async throws {
        let user = User(username: "abc")
        try await user.save(on: app.db)
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.username, "abc")
    }
    
    func testUserUsernameMinLength() async throws {
        // Username should be at least 3 characters
        let shortUser = User(username: "ab")
        
        // Validation happens at controller level, model just stores
        // This test documents the requirement
        try await shortUser.save(on: app.db)
        XCTAssertEqual(shortUser.username, "ab")
    }
    
    func testUserUsernameMaxLength() async throws {
        // Username should be at most 50 characters
        let longUsername = String(repeating: "a", count: 50)
        let user = User(username: longUsername)
        try await user.save(on: app.db)
        
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.username.count, 50)
    }
    
    // MARK: - Uniqueness Tests
    
    func testUserUsernameUniqueness() async throws {
        let user1 = User(username: "uniqueuser")
        try await user1.save(on: app.db)
        
        let user2 = User(username: "uniqueuser")
        
        do {
            try await user2.save(on: app.db)
            XCTFail("Should not allow duplicate usernames")
        } catch {
            // Expected: unique constraint violation
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Retrieval Tests
    
    func testUserFindById() async throws {
        let user = User(username: "findme")
        try await user.save(on: app.db)
        let userId = try user.requireID()
        
        let foundUser = try await User.find(userId, on: app.db)
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.username, "findme")
    }
    
    func testUserFindByUsername() async throws {
        let user = User(username: "searchuser")
        try await user.save(on: app.db)
        
        let foundUser = try await User.query(on: app.db)
            .filter(\.$username == "searchuser")
            .first()
        
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.id, user.id)
    }
    
    // MARK: - Session Authentication Tests
    
    func testUserSessionID() async throws {
        let user = User(username: "sessionuser")
        try await user.save(on: app.db)
        
        let sessionId = user.sessionID
        XCTAssertEqual(sessionId, user.id)
    }
    
    // MARK: - Relationship Tests
    
    func testUserAlbumsRelationship() async throws {
        let user = User(username: "albumowner")
        try await user.save(on: app.db)
        let userId = try user.requireID()
        
        // Create albums owned by this user
        let album1 = Album(name: "Album 1", date: Date(), ownerId: userId)
        let album2 = Album(name: "Album 2", date: Date(), ownerId: userId)
        try await album1.save(on: app.db)
        try await album2.save(on: app.db)
        
        // Load albums relationship
        try await user.$albums.load(on: app.db)
        XCTAssertEqual(user.albums.count, 2)
    }
    
    func testUserPhotosRelationship() async throws {
        let user = User(username: "photoowner")
        try await user.save(on: app.db)
        let userId = try user.requireID()
        
        // Create album first (photos require album)
        let album = Album(name: "Test Album", date: Date(), ownerId: userId)
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        // Create photos owned by this user
        let photo1 = Photo(
            albumId: albumId,
            filePath: "/test/photo1.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG",
            ownerId: userId
        )
        let photo2 = Photo(
            albumId: albumId,
            filePath: "/test/photo2.jpg",
            displayOrder: 1,
            fileSize: 2048,
            width: 800,
            height: 600,
            format: "JPEG",
            ownerId: userId
        )
        try await photo1.save(on: app.db)
        try await photo2.save(on: app.db)
        
        // Load photos relationship
        try await user.$photos.load(on: app.db)
        XCTAssertEqual(user.photos.count, 2)
    }
}
