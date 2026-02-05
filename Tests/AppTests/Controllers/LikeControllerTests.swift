// Tests/AppTests/Controllers/LikeControllerTests.swift
// T019: Unit tests for LikeController (TDD - write first, ensure they fail)

@testable import PhotoAlbumOrganizer
import XCTVapor

final class LikeControllerTests: XCTestCase {
    var app: Application!
    var owner: User!
    var liker: User!
    var album: Album!
    var photo: Photo!
    var likerCookies: HTTPCookies!
    var ownerCookies: HTTPCookies!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
        
        // Create owner user
        owner = User(username: "photoowner")
        try await owner.save(on: app.db)
        let ownerId = try owner.requireID()
        
        // Create liker user
        liker = User(username: "photoliker")
        try await liker.save(on: app.db)
        
        // Create album owned by owner
        album = Album(name: "Test Album", date: Date(), ownerId: ownerId)
        try await album.save(on: app.db)
        
        // Create photo owned by owner
        photo = Photo(
            albumId: try album.requireID(),
            filePath: "/test/photo.jpg",
            displayOrder: 0,
            fileSize: 1024,
            width: 800,
            height: 600,
            format: "JPEG",
            ownerId: ownerId
        )
        try await photo.save(on: app.db)
        
        // Login both users to get session cookies
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "photoliker"])
        }, afterResponse: { res in
            self.likerCookies = res.headers.setCookie ?? HTTPCookies()
        })
        
        try await app.test(.POST, "/api/users/login", beforeRequest: { req in
            try req.content.encode(["username": "photoowner"])
        }, afterResponse: { res in
            self.ownerCookies = res.headers.setCookie ?? HTTPCookies()
        })
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
        owner = nil
        liker = nil
        album = nil
        photo = nil
        likerCookies = nil
        ownerCookies = nil
    }
    
    // MARK: - Photo Like API Tests
    
    func testLikePhotoSuccess() async throws {
        let photoId = try photo.requireID()
        
        try await app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(LikeResponse.self)
            XCTAssertNotNil(response.id)
            XCTAssertEqual(response.likeCount, 1)
            XCTAssertTrue(response.isLikedByCurrentUser)
        })
    }
    
    func testLikePhotoRequiresAuth() async throws {
        let photoId = try photo.requireID()
        
        try await app.test(.POST, "/api/photos/\(photoId)/like", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testLikePhotoSelfLikeRejected() async throws {
        let photoId = try photo.requireID()
        
        // Owner tries to like their own photo
        try await app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = self.ownerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    func testLikePhotoNotFound() async throws {
        let fakeId = UUID()
        
        try await app.test(.POST, "/api/photos/\(fakeId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testUnlikePhotoSuccess() async throws {
        let photoId = try photo.requireID()
        
        // First like
        try await app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        })
        
        // Then unlike
        try await app.test(.DELETE, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
        
        // Verify like is gone
        try await app.test(.GET, "/api/photos/\(photoId)/likes", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            let info = try res.content.decode(LikeInfoResponse.self)
            XCTAssertEqual(info.likeCount, 0)
            XCTAssertFalse(info.isLikedByCurrentUser)
        })
    }
    
    func testUnlikePhotoRequiresAuth() async throws {
        let photoId = try photo.requireID()
        
        try await app.test(.DELETE, "/api/photos/\(photoId)/like", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testGetPhotoLikes() async throws {
        let photoId = try photo.requireID()
        
        // Initially no likes
        try await app.test(.GET, "/api/photos/\(photoId)/likes", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let info = try res.content.decode(LikeInfoResponse.self)
            XCTAssertEqual(info.likeCount, 0)
            XCTAssertFalse(info.isLikedByCurrentUser)
        })
        
        // Add a like
        try await app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        })
        
        // Check count
        try await app.test(.GET, "/api/photos/\(photoId)/likes", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            let info = try res.content.decode(LikeInfoResponse.self)
            XCTAssertEqual(info.likeCount, 1)
            XCTAssertTrue(info.isLikedByCurrentUser)
        })
    }
    
    func testGetPhotoLikesWithoutAuth() async throws {
        let photoId = try photo.requireID()
        
        // Should work without auth but isLikedByCurrentUser should be false
        try await app.test(.GET, "/api/photos/\(photoId)/likes", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let info = try res.content.decode(LikeInfoResponse.self)
            XCTAssertFalse(info.isLikedByCurrentUser)
        })
    }
    
    // MARK: - Album Like API Tests
    
    func testLikeAlbumSuccess() async throws {
        let albumId = try album.requireID()
        
        try await app.test(.POST, "/api/albums/\(albumId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(LikeResponse.self)
            XCTAssertNotNil(response.id)
            XCTAssertEqual(response.likeCount, 1)
            XCTAssertTrue(response.isLikedByCurrentUser)
        })
    }
    
    func testLikeAlbumRequiresAuth() async throws {
        let albumId = try album.requireID()
        
        try await app.test(.POST, "/api/albums/\(albumId)/like", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testLikeAlbumSelfLikeRejected() async throws {
        let albumId = try album.requireID()
        
        // Owner tries to like their own album
        try await app.test(.POST, "/api/albums/\(albumId)/like", beforeRequest: { req in
            req.headers.cookie = self.ownerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    func testUnlikeAlbumSuccess() async throws {
        let albumId = try album.requireID()
        
        // First like
        try await app.test(.POST, "/api/albums/\(albumId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        })
        
        // Then unlike
        try await app.test(.DELETE, "/api/albums/\(albumId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }
    
    func testGetAlbumLikes() async throws {
        let albumId = try album.requireID()
        
        try await app.test(.GET, "/api/albums/\(albumId)/likes", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let info = try res.content.decode(LikeInfoResponse.self)
            XCTAssertEqual(info.likeCount, 0)
        })
    }
    
    // MARK: - Likers List Tests (User Story 4)
    
    func testGetPhotoLikers() async throws {
        let photoId = try photo.requireID()
        
        // Add a like first
        try await app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        })
        
        try await app.test(.GET, "/api/photos/\(photoId)/likers", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(LikersResponse.self)
            XCTAssertEqual(response.totalCount, 1)
            XCTAssertEqual(response.likers.count, 1)
            XCTAssertEqual(response.likers.first?.username, "photoliker")
        })
    }
    
    func testGetPhotoLikersWithLimit() async throws {
        let photoId = try photo.requireID()
        
        // Create multiple likers
        for i in 1...5 {
            let user = User(username: "liker\(i)")
            try await user.save(on: app.db)
            
            // Login and like
            var cookies: HTTPCookies?
            try await app.test(.POST, "/api/users/login", beforeRequest: { req in
                try req.content.encode(["username": "liker\(i)"])
            }, afterResponse: { res in
                cookies = res.headers.setCookie
            })
            
            try await app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
                req.headers.cookie = cookies
            })
        }
        
        // Get with limit
        try await app.test(.GET, "/api/photos/\(photoId)/likers?limit=3", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            let response = try res.content.decode(LikersResponse.self)
            XCTAssertEqual(response.totalCount, 5)
            XCTAssertEqual(response.likers.count, 3)
            XCTAssertTrue(response.hasMore)
        })
    }
    
    func testGetAlbumLikers() async throws {
        let albumId = try album.requireID()
        
        // Add a like first
        try await app.test(.POST, "/api/albums/\(albumId)/like", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        })
        
        try await app.test(.GET, "/api/albums/\(albumId)/likers", beforeRequest: { req in
            req.headers.cookie = self.likerCookies
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(LikersResponse.self)
            XCTAssertEqual(response.totalCount, 1)
        })
    }
}

// MARK: - Response DTOs for tests

struct LikeResponse: Content {
    let id: UUID
    let likeCount: Int
    let isLikedByCurrentUser: Bool
}

struct LikeInfoResponse: Content {
    let likeCount: Int
    let isLikedByCurrentUser: Bool
    let isOwnedByCurrentUser: Bool?
}

struct LikersResponse: Content {
    let totalCount: Int
    let likers: [LikerInfo]
    let hasMore: Bool
}

struct LikerInfo: Content {
    let username: String
    let likedAt: Date
}
