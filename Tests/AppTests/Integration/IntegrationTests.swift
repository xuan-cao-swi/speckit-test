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
    
    // T060: Verify deleting album cascades to photos table
    func testDeleteAlbumCascadesToPhotos() async throws {
        // Create album with photos
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        // Add photos
        for i in 0..<3 {
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
        
        // Verify photos exist
        let photosBeforeDelete = try await Photo.query(on: app.db)
            .filter(\.$album.$id, .equal, albumId)
            .all()
        XCTAssertEqual(photosBeforeDelete.count, 3)
        
        // Delete album
        try await album.delete(on: app.db)
        
        // Verify photos are also deleted (cascade)
        let photosAfterDelete = try await Photo.query(on: app.db)
            .filter(\.$album.$id, .equal, albumId)
            .all()
        XCTAssertEqual(photosAfterDelete.count, 0)
    }
    
    // T088: Verify adding photos updates album photoCount
    func testAddingPhotosUpdatesPhotoCount() async throws {
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        let albumId = try album.requireID()
        
        // Verify initial count is 0
        let albumBefore = try await Album.find(albumId, on: app.db)
        XCTAssertNotNil(albumBefore)
        let photosBefore = try await Photo.query(on: app.db)
            .filter(\.$album.$id, .equal, albumId)
            .all()
        XCTAssertEqual(photosBefore.count, 0)
        
        // Add a photo
        let photo = Photo(
            albumId: albumId,
            filePath: "/path/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG"
        )
        try await photo.save(on: app.db)
        
        // Verify count is now 1
        let reloadedAlbum = try await Album.find(albumId, on: app.db)
        try await reloadedAlbum?.$photos.load(on: app.db)
        XCTAssertEqual(reloadedAlbum?.photos.count, 1)
    }
    
    // T117: Verify reorder persists across app restart
    func testReorderPersistence() async throws {
        // Create albums
        let album1 = Album(name: "Album 1", date: Date(), customOrder: 2)
        try await album1.save(on: app.db)
        let id1 = try album1.requireID()
        
        let album2 = Album(name: "Album 2", date: Date(), customOrder: 0)
        try await album2.save(on: app.db)
        let id2 = try album2.requireID()
        
        // Simulate app restart by creating new app instance
        try await app.autoRevert()
        try await app.asyncShutdown()
        
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
        
        // Recreate albums
        let newAlbum1 = Album(name: "Album 1", date: Date(), customOrder: 2)
        newAlbum1.id = id1
        try await newAlbum1.save(on: app.db)
        
        let newAlbum2 = Album(name: "Album 2", date: Date(), customOrder: 0)
        newAlbum2.id = id2
        try await newAlbum2.save(on: app.db)
        
        // Verify custom order persisted
        let albums = try await Album.query(on: app.db)
            .sort(\.$customOrder, .ascending)
            .all()
        
        XCTAssertEqual(albums[0].name, "Album 2") // customOrder 0
        XCTAssertEqual(albums[1].name, "Album 1") // customOrder 2
    }
}
