// Tests/AppTests/TestUtils.swift
// T003: Test utility functions and configuration for Social Media Likes feature

@testable import PhotoAlbumOrganizer
import XCTVapor
import Fluent

// MARK: - Test Application Factory

/// Creates a configured application instance for testing
/// Uses in-memory SQLite database for isolation and speed
func makeTestApp() async throws -> Application {
    let app = try await Application.make(.testing)
    try await configure(app)
    try await app.autoMigrate()
    return app
}

/// Cleans up test application resources
func shutdownTestApp(_ app: Application) async throws {
    try await app.autoRevert()
    try await app.asyncShutdown()
}

// MARK: - Test User Factory

/// Creates a test user with the given username
/// - Parameters:
///   - username: Username for the test user (default: "testuser")
///   - db: Database to save the user to
/// - Returns: The created User instance
func createTestUser(username: String = "testuser", on db: Database) async throws -> User {
    let user = User(username: username)
    try await user.save(on: db)
    return user
}

/// Creates multiple test users
/// - Parameters:
///   - count: Number of users to create
///   - db: Database to save users to
/// - Returns: Array of created User instances
func createTestUsers(count: Int, on db: Database) async throws -> [User] {
    var users: [User] = []
    for i in 1...count {
        let user = try await createTestUser(username: "user\(i)", on: db)
        users.append(user)
    }
    return users
}

// MARK: - Test Album Factory

/// Creates a test album owned by the specified user
/// - Parameters:
///   - name: Album name (default: "Test Album")
///   - owner: User who owns the album
///   - db: Database to save the album to
/// - Returns: The created Album instance
func createTestAlbum(name: String = "Test Album", ownedBy owner: User, on db: Database) async throws -> Album {
    let album = Album(name: name, date: Date(), ownerId: try owner.requireID())
    try await album.save(on: db)
    return album
}

// MARK: - Test Photo Factory

/// Creates a test photo in the specified album owned by the specified user
/// - Parameters:
///   - album: Album to add the photo to
///   - owner: User who owns the photo
///   - displayOrder: Display order (default: 0)
///   - db: Database to save the photo to
/// - Returns: The created Photo instance
func createTestPhoto(
    in album: Album,
    ownedBy owner: User,
    displayOrder: Int = 0,
    on db: Database
) async throws -> Photo {
    let photo = Photo(
        albumId: try album.requireID(),
        filePath: "/test/photo-\(UUID().uuidString).jpg",
        displayOrder: displayOrder,
        fileSize: 1024,
        width: 800,
        height: 600,
        format: "JPEG",
        ownerId: try owner.requireID()
    )
    try await photo.save(on: db)
    return photo
}
