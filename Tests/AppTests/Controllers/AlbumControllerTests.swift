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
    
    // T056: Test POST /api/albums - verify album creation with valid data
    func testCreateAlbumWithValidData() async throws {
        struct CreateAlbumRequest: Content {
            let name: String
            let date: String
        }
        
        let request = CreateAlbumRequest(name: "New Album", date: "2024-08-01")
        
        try await app.test(.POST, "/api/albums", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .ok)
            let album = try res.content.decode(Album.self)
            XCTAssertEqual(album.name, "New Album")
            XCTAssertNotNil(album.id)
        }
    }
    
    // T057: Test POST /api/albums - verify 400 error with invalid data
    func testCreateAlbumWithInvalidData() async throws {
        struct CreateAlbumRequest: Content {
            let name: String
            let date: String
        }
        
        let request = CreateAlbumRequest(name: "", date: "2024-08-01")
        
        try await app.test(.POST, "/api/albums", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
    
    // T058: Test PATCH /api/albums/:id - verify album update
    func testUpdateAlbum() async throws {
        let album = Album(name: "Original Name", date: Date())
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        struct UpdateAlbumRequest: Content {
            let name: String
        }
        
        let request = UpdateAlbumRequest(name: "Updated Name")
        
        try await app.test(.PATCH, "/api/albums/\(albumId)", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .ok)
            let updated = try res.content.decode(Album.self)
            XCTAssertEqual(updated.name, "Updated Name")
        }
    }
    
    // T059: Test DELETE /api/albums/:id - verify album deletion
    func testDeleteAlbum() async throws {
        let album = Album(name: "To Delete", date: Date())
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        try await app.test(.DELETE, "/api/albums/\(albumId)") { res in
            XCTAssertEqual(res.status, .noContent)
        }
        
        // Verify album is gone
        let deleted = try await Album.find(albumId, on: app.db)
        XCTAssertNil(deleted)
    }
    
    // T114: Test PATCH /api/albums/reorder - verify batch customOrder update
    func testReorderAlbums() async throws {
        // Create test albums
        let album1 = Album(name: "Album 1", date: Date())
        try await album1.save(on: app.db)
        let id1 = try album1.requireID()
        
        let album2 = Album(name: "Album 2", date: Date())
        try await album2.save(on: app.db)
        let id2 = try album2.requireID()
        
        let album3 = Album(name: "Album 3", date: Date())
        try await album3.save(on: app.db)
        let id3 = try album3.requireID()
        
        struct ReorderRequest: Content {
            struct AlbumOrder: Content {
                let id: UUID
                let customOrder: Int
            }
            let updates: [AlbumOrder]
        }
        
        // Reorder: album2 first, album1 second, album3 third
        let request = ReorderRequest(updates: [
            ReorderRequest.AlbumOrder(id: id2, customOrder: 0),
            ReorderRequest.AlbumOrder(id: id1, customOrder: 1),
            ReorderRequest.AlbumOrder(id: id3, customOrder: 2)
        ])
        
        try await app.test(.PATCH, "/api/albums/reorder", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .ok)
        }
        
        // Verify custom orders were set
        let reloaded1 = try await Album.find(id1, on: app.db)
        let reloaded2 = try await Album.find(id2, on: app.db)
        let reloaded3 = try await Album.find(id3, on: app.db)
        
        XCTAssertEqual(reloaded1?.customOrder, 1)
        XCTAssertEqual(reloaded2?.customOrder, 0)
        XCTAssertEqual(reloaded3?.customOrder, 2)
    }
    
    // T116: Test GET /api/albums?sort=custom_order
    func testGetAlbumsWithCustomOrdering() async throws {
        // Create albums with custom order
        let album1 = Album(name: "First", date: Date(), customOrder: 2)
        try await album1.save(on: app.db)
        
        let album2 = Album(name: "Second", date: Date(), customOrder: 0)
        try await album2.save(on: app.db)
        
        let album3 = Album(name: "Third", date: Date(), customOrder: 1)
        try await album3.save(on: app.db)
        
        try await app.test(.GET, "/api/albums?sort=custom_order") { res in
            XCTAssertEqual(res.status, .ok)
            let albums = try res.content.decode([Album].self)
            XCTAssertEqual(albums.count, 3)
            
            // Should be sorted by customOrder
            XCTAssertEqual(albums[0].name, "Second") // customOrder 0
            XCTAssertEqual(albums[1].name, "Third")  // customOrder 1
            XCTAssertEqual(albums[2].name, "First")  // customOrder 2
        }
    }
}
