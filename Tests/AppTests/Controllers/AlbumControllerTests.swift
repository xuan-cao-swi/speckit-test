@testable import PhotoAlbumOrganizer
import XCTVapor

final class AlbumControllerTests: XCTestCase {
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
    
    // T030: Test GET /api/albums returns empty array initially
    func testGetAlbumsReturnsEmptyArray() async throws {
        try await app.test(.GET, "/api/albums") { res in
            XCTAssertEqual(res.status, .ok)
            let albums = try res.content.decode([Album].self)
            XCTAssertEqual(albums.count, 0)
        }
    }
    
    // T031: Test GET /api/albums returns albums sorted by date
    func testGetAlbumsReturnsSortedByDate() async throws {
        // Create albums with different dates
        let album1 = Album(name: "Recent Album", date: Date())
        let album2 = Album(name: "Old Album", date: Date(timeIntervalSince1970: 0))
        let album3 = Album(name: "Middle Album", date: Date(timeIntervalSinceNow: -86400))
        
        try await album1.save(on: app.db)
        try await album2.save(on: app.db)
        try await album3.save(on: app.db)
        
        try await app.test(.GET, "/api/albums") { res in
            XCTAssertEqual(res.status, .ok)
            let albums = try res.content.decode([Album].self)
            XCTAssertEqual(albums.count, 3)
            
            // Should be sorted by date descending (most recent first)
            // This test will fail until the controller is implemented
        }
    }
    
    // T032: Test GET /api/albums/:id returns album details
    func testGetAlbumById() async throws {
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        
        let albumId = try album.requireID()
        
        try await app.test(.GET, "/api/albums/\(albumId)") { res in
            XCTAssertEqual(res.status, .ok)
            let returnedAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(returnedAlbum.id, albumId)
            XCTAssertEqual(returnedAlbum.name, "Test Album")
        }
    }
    
    func testGetAlbumByIdNotFound() async throws {
        let fakeId = UUID()
        
        try await app.test(.GET, "/api/albums/\(fakeId)") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}
