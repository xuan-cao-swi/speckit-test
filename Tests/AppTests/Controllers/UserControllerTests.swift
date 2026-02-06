// Tests/AppTests/Controllers/UserControllerTests.swift
// T015: Unit tests for UserController (login, logout, me endpoints)

@testable import PhotoAlbumOrganizer
import XCTVapor
import Fluent

final class UserControllerTests: XCTestCase {
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
    
    // MARK: - Login Tests
    
    func testLoginCreatesNewUser() async throws {
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "newuser"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let user = try res.content.decode(UserResponse.self)
            XCTAssertEqual(user.username, "newuser")
            XCTAssertNotNil(user.id)
        })
        
        // Verify user was created in database
        let user = try await User.query(on: app.db)
            .filter(\.$username == "newuser")
            .first()
        XCTAssertNotNil(user)
    }
    
    func testLoginExistingUser() async throws {
        // Create user first
        let existingUser = User(username: "existinguser")
        try await existingUser.save(on: app.db)
        let existingId = try existingUser.requireID()
        
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "existinguser"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let user = try res.content.decode(UserResponse.self)
            XCTAssertEqual(user.username, "existinguser")
            XCTAssertEqual(user.id, existingId)  // Same user ID
        })
    }
    
    func testLoginSetsSessionCookie() async throws {
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "sessiontest"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            // Check for session cookie
            let cookies = res.headers.setCookie
            XCTAssertNotNil(cookies, "Should have Set-Cookie header")
        })
    }
    
    func testLoginRejectsShortUsername() async throws {
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "ab"])  // Too short
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    func testLoginRejectsTooLongUsername() async throws {
        let longUsername = String(repeating: "a", count: 51)  // Too long
        
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": longUsername])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    func testLoginRejectsInvalidCharacters() async throws {
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "user@name"])  // Invalid character
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    func testLoginAcceptsValidSpecialCharacters() async throws {
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "user-name_123"])  // Valid characters
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let user = try res.content.decode(UserResponse.self)
            XCTAssertEqual(user.username, "user-name_123")
        })
    }
    
    // MARK: - Logout Tests
    
    func testLogoutRequiresAuth() async throws {
        try await app.test(.POST, "/api/users/logout", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testLogoutWithSession() async throws {
        // Login first
        var sessionCookie: HTTPCookies?
        
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "logouttest"])
        }, afterResponse: { res in
            sessionCookie = res.headers.setCookie
        })
        
        // Logout with session
        try await app.test(.POST, "/api/users/logout", beforeRequest: { req in
            if let cookies = sessionCookie {
                req.headers.cookie = cookies
            }
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }
    
    // MARK: - Get Current User Tests
    
    func testGetMeRequiresAuth() async throws {
        try await app.test(.GET, "/api/users/me", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testGetMeWithSession() async throws {
        // Login first
        var sessionCookie: HTTPCookies?
        
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "metest"])
        }, afterResponse: { res in
            sessionCookie = res.headers.setCookie
        })
        
        // Get current user with session
        try await app.test(.GET, "/api/users/me", beforeRequest: { req in
            if let cookies = sessionCookie {
                req.headers.cookie = cookies
            }
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let user = try res.content.decode(UserResponse.self)
            XCTAssertEqual(user.username, "metest")
        })
    }
    
    func testGetMeAfterLogout() async throws {
        // Login first
        var sessionCookie: HTTPCookies?
        
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "logoutmetest"])
        }, afterResponse: { res in
            sessionCookie = res.headers.setCookie
        })
        
        // Logout
        try await app.test(.POST, "/api/users/logout", beforeRequest: { req in
            if let cookies = sessionCookie {
                req.headers.cookie = cookies
            }
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
        
        // Get me should fail after logout
        try await app.test(.GET, "/api/users/me", beforeRequest: { req in
            if let cookies = sessionCookie {
                req.headers.cookie = cookies
            }
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
}
