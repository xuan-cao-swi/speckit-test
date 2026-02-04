@testable import PhotoAlbumOrganizer
import XCTVapor

final class IntegrationTests: XCTestCase {
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
    
    // T034: Verify album with photos returns correct photoCount
    func testAlbumPhotoCount() async throws {
        // Create album
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        // Initially no photos
        let loadedAlbum1 = try await Album.find(albumId, on: app.db)
        try await loadedAlbum1?.$photos.load(on: app.db)
        
        XCTAssertNotNil(loadedAlbum1)
        XCTAssertEqual(loadedAlbum1?.photos.count, 0)
        
        // Add photos
        for i in 0..<5 {
            let photo = Photo(
                albumId: albumId,
                filePath: "/path/photo\(i).jpg",
                displayOrder: i,
                fileSize: 1024,
                width: 800,
                height: 600,
                format: "JPEG"
            )
            try await photo.save(on: app.db)
        }
        
        // Verify photo count
        let loadedAlbum2 = try await Album.find(albumId, on: app.db)
        try await loadedAlbum2?.$photos.load(on: app.db)
        
        XCTAssertNotNil(loadedAlbum2)
        XCTAssertEqual(loadedAlbum2?.photos.count, 5)
    }
}
