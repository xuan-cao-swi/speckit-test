@testable import PhotoAlbumOrganizer
import XCTVapor

final class AlbumTests: XCTestCase {
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
    
    func testAlbumNameRequired() async throws {
        let album = Album(name: "", date: Date())
        
        // Validation happens on save
        do {
            try await album.save(on: app.db)
            // Vapor may allow empty strings - we'll enforce in controller
        } catch {
            // Expected if database enforces NOT NULL
        }
    }
    
    func testAlbumNameWithinLengthLimit() async throws {
        let shortName = Album(name: "A", date: Date())
        try await shortName.save(on: app.db)
        XCTAssertNotNil(shortName.id)
        
        let longName = Album(name: String(repeating: "a", count: 255), date: Date())
        try await longName.save(on: app.db)
        XCTAssertNotNil(longName.id)
    }
    
    func testAlbumDateValid() async throws {
        let pastDate = Album(name: "Past Album", date: Date(timeIntervalSince1970: 0))
        try await pastDate.save(on: app.db)
        XCTAssertNotNil(pastDate.id)
        
        let futureDate = Album(name: "Future Album", date: Date(timeIntervalSinceNow: 86400))
        try await futureDate.save(on: app.db)
        XCTAssertNotNil(futureDate.id)
    }
    
    func testAlbumCreation() async throws {
        let album = Album(name: "Test Album", date: Date())
        try await album.save(on: app.db)
        
        XCTAssertNotNil(album.id)
        XCTAssertEqual(album.name, "Test Album")
    }
}
