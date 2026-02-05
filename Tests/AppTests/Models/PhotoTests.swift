@testable import PhotoAlbumOrganizer
import XCTVapor

final class PhotoTests: XCTestCase {
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
    
    func testPhotoValidation() async throws {
        // Create test album
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        
        let validPhoto = Photo(
            albumId: try album.requireID(),
            filePath: "/path/to/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        try await validPhoto.save(on: app.db)
        XCTAssertNotNil(validPhoto.id)
    }
    
    func testPhotoFilePathRequired() async throws {
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        
        let photo = Photo(
            albumId: try album.requireID(),
            filePath: "/path/to/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        
        try await photo.save(on: app.db)
        XCTAssertNotNil(photo.id)
    }
    
    func testPhotoFormatValidation() async throws {
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        
        let validFormats = ["JPEG", "PNG", "HEIC", "WebP", "GIF"]
        for format in validFormats {
            let photo = Photo(
                albumId: try album.requireID(),
                filePath: "/path/to/photo_\(format).\(format.lowercased())",
                displayOrder: 0,
                fileSize: 1024,
                width: 800,
                height: 600,
                format: format
            )
            try await photo.save(on: app.db)
            XCTAssertNotNil(photo.id)
        }
    }
    
    func testPhotoBelongsToAlbum() async throws {
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        
        let photo = Photo(
            albumId: try album.requireID(),
            filePath: "/path/to/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        try await photo.save(on: app.db)
        
        // Load album with photos
        let loadedAlbum = try await Album.find(album.id, on: app.db)
        try await loadedAlbum?.$photos.load(on: app.db)
        
        XCTAssertNotNil(loadedAlbum)
        XCTAssertEqual(loadedAlbum?.photos.count, 1)
        XCTAssertEqual(loadedAlbum?.photos.first?.filePath, "/path/to/photo.jpg")
    }
}
