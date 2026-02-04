@testable import PhotoAlbumOrganizer
import XCTVapor

final class PhotoControllerTests: XCTestCase {
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
    
    // T033: Test GET /api/albums/:id/photos returns photos sorted by displayOrder
    func testGetPhotosForAlbumSortedByDisplayOrder() async throws {
        // Create album
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        // Create photos with different display orders
        let photo1 = Photo(
            albumId: albumId,
            filePath: "/path/photo1.jpg",
            displayOrder: 2,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        let photo2 = Photo(
            albumId: albumId,
            filePath: "/path/photo2.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        let photo3 = Photo(
            albumId: albumId,
            filePath: "/path/photo3.jpg",
            displayOrder: 1,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        
        try await photo1.save(on: app.db)
        try await photo2.save(on: app.db)
        try await photo3.save(on: app.db)
        
        try await app.test(.GET, "/api/albums/\(albumId)/photos") { res in
            XCTAssertEqual(res.status, .ok)
            let photos = try res.content.decode([Photo].self)
            XCTAssertEqual(photos.count, 3)
            
            // Should be sorted by displayOrder ascending
            XCTAssertEqual(photos[0].filePath, "/path/photo2.jpg") // displayOrder 0
            XCTAssertEqual(photos[1].filePath, "/path/photo3.jpg") // displayOrder 1
            XCTAssertEqual(photos[2].filePath, "/path/photo1.jpg") // displayOrder 2
        }
    }
    
    func testGetPhotosForNonExistentAlbum() async throws {
        let fakeId = UUID()
        
        try await app.test(.GET, "/api/albums/\(fakeId)/photos") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}
