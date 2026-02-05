// T159-T161: Tests for User Preferences
import XCTest
@testable import PhotoAlbumOrganizer
import XCTVapor

final class PreferenceControllerTests: XCTestCase {
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
    
    // T159: Test GET /api/preferences - verify default preferences on first launch
    func testGetPreferencesReturnsDefaults() async throws {
        try await app.test(.GET, "/api/preferences") { res in
            XCTAssertEqual(res.status, .ok)
            let prefs = try res.content.decode(UserPreference.self)
            
            // Verify defaults (DESC = newest first)
            XCTAssertEqual(prefs.sortDirection, "DESC")
            XCTAssertEqual(prefs.thumbnailSize, 200)
            XCTAssertEqual(prefs.theme, "light")
        }
    }
    
    // T160: Test PATCH /api/preferences - verify preference updates
    func testUpdatePreferences() async throws {
        struct UpdateRequest: Content {
            let sortDirection: String?
            let thumbnailSize: Int?
            let theme: String?
        }
        
        let request = UpdateRequest(
            sortDirection: "DESC",
            thumbnailSize: 300,
            theme: "dark"
        )
        
        try await app.test(.PATCH, "/api/preferences", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .ok)
            let prefs = try res.content.decode(UserPreference.self)
            
            XCTAssertEqual(prefs.sortDirection, "DESC")
            XCTAssertEqual(prefs.thumbnailSize, 300)
            XCTAssertEqual(prefs.theme, "dark")
        }
    }
    
    // T161: Test validation - thumbnailSize must be 100-500
    func testUpdatePreferencesWithInvalidThumbnailSize() async throws {
        struct UpdateRequest: Content {
            let thumbnailSize: Int
        }
        
        let request = UpdateRequest(thumbnailSize: 50) // Below minimum
        
        try await app.test(.PATCH, "/api/preferences", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
    
    func testUpdatePreferencesWithInvalidSortDirection() async throws {
        struct UpdateRequest: Content {
            let sortDirection: String
        }
        
        let request = UpdateRequest(sortDirection: "INVALID")
        
        try await app.test(.PATCH, "/api/preferences", beforeRequest: { req in
            try req.content.encode(request)
        }) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
}
