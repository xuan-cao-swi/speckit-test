# Quickstart: Social Media Likes Implementation

**Phase**: 1 - Design & Contracts  
**Date**: 2026-02-05  
**Purpose**: Development guide for implementing the social media likes feature

## Prerequisites

- Existing photo album application from `001-photo-album` feature
- Swift 5.9+ installed
- Vapor 4.x project configured
- SQLite database with albums and photos tables

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                     Frontend (Vanilla JS)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Like Button  │  │ Like Counter │  │ Polling Loop │   │
│  │ Component    │  │ Display      │  │ (2s interval)│   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                  │                  │           │
└─────────┼──────────────────┼──────────────────┼───────────┘
          │                  │                  │
          │ POST /like       │ GET /likes       │ (Fetch API)
          ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│                  Vapor Backend (Swift)                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │              LikeController                       │   │
│  │  - POST /photos/:id/like   (create like)         │   │
│  │  - DELETE /photos/:id/like (remove like)         │   │
│  │  - GET /photos/:id/likes   (get count + status)  │   │
│  └──────────────────┬───────────────────────────────┘   │
│                     │                                    │
│  ┌──────────────────▼───────────────────────────────┐   │
│  │              LikeService                          │   │
│  │  - validateNotSelfLike() (business logic)        │   │
│  │  - createLike() (idempotent)                     │   │
│  │  - deleteLike() (idempotent)                     │   │
│  └──────────────────┬───────────────────────────────┘   │
│                     │                                    │
│  ┌──────────────────▼───────────────────────────────┐   │
│  │              Fluent ORM                           │   │
│  │  - Like model (User + Photo/Album relationship)  │   │
│  │  - Unique constraints (prevent duplicates)       │   │
│  │  - Foreign keys (referential integrity)          │   │
│  └──────────────────┬───────────────────────────────┘   │
└────────────────────┼────────────────────────────────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │   SQLite Database   │
          │  - users            │
          │  - albums (+ owner) │
          │  - photos (+ owner) │
          │  - likes            │
          └─────────────────────┘
```

## Implementation Phases

### Phase 1: Database Setup (TDD: Migration Tests)

**Goal**: Create User and Like models with proper constraints

#### 1.1 Create User Model

**File**: `Sources/App/Models/User.swift`

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    // Relationships
    @Children(for: \.$user)
    var likes: [Like]
    
    @Children(for: \.$owner)
    var ownedAlbums: [Album]
    
    @Children(for: \.$owner)
    var ownedPhotos: [Photo]
    
    init() { }
    
    init(id: UUID? = nil, username: String) {
        self.id = id
        self.username = username
    }
}

// Validation
extension User: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .count(3...50))
        validations.add("username", as: String.self, is: .alphanumeric || .characterSet(.init(charactersIn: "_-")))
    }
}
```

#### 1.2 Create User Migration

**File**: `Sources/App/Migrations/CreateUser.swift`

```swift
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("created_at", .datetime, .required)
            .unique(on: "username")  // Case-insensitive enforced in app logic
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

#### 1.3 Extend Album/Photo with Owner

**File**: `Sources/App/Models/Album.swift` (modification)

```swift
// Add to existing Album model
@Parent(key: "owner_id")
var owner: User
```

**File**: `Sources/App/Migrations/UpdateAlbumWithOwner.swift` (new)

```swift
import Fluent

struct UpdateAlbumWithOwner: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Create default system user if doesn't exist
        let systemUser = User(username: "system")
        try await systemUser.save(on: database)
        
        // Add owner_id column
        try await database.schema("albums")
            .field("owner_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .update()
        
        // Backfill existing albums with system user
        try await database.raw("""
            UPDATE albums SET owner_id = '\(systemUser.requireID())'
            WHERE owner_id IS NULL
        """).run()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("albums")
            .deleteField("owner_id")
            .update()
    }
}
```

*(Repeat similar pattern for Photo model)*

#### 1.4 Create Like Model

**File**: `Sources/App/Models/Like.swift`

```swift
import Fluent
import Vapor

final class Like: Model, Content {
    static let schema = "likes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @OptionalParent(key: "photo_id")
    var photo: Photo?
    
    @OptionalParent(key: "album_id")
    var album: Album?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, userId: UUID, photoId: UUID? = nil, albumId: UUID? = nil) {
        self.id = id
        self.$user.id = userId
        self.$photo.id = photoId
        self.$album.id = albumId
    }
}

// Validation
extension Like: Validatable {
    static func validations(_ validations: inout Validations) {
        // XOR validation: exactly one of photoId or albumId must be set
        validations.add("target", as: String.self, is: .valid) { like in
            let hasPhoto = like.$photo.id != nil
            let hasAlbum = like.$album.id != nil
            return (hasPhoto && !hasAlbum) || (!hasPhoto && hasAlbum)
        }
    }
}
```

#### 1.5 Create Like Migration

**File**: `Sources/App/Migrations/CreateLike.swift`

```swift
import Fluent
import SQLKit

struct CreateLike: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("likes")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("photo_id", .uuid, .references("photos", "id", onDelete: .cascade))
            .field("album_id", .uuid, .references("albums", "id", onDelete: .cascade))
            .field("created_at", .datetime, .required)
            .create()
        
        // XOR constraint: exactly one of photo_id or album_id must be non-null
        if let sql = database as? SQLDatabase {
            try await sql.raw("""
                CREATE TRIGGER check_like_target_xor
                BEFORE INSERT ON likes
                FOR EACH ROW
                BEGIN
                    SELECT CASE
                        WHEN (NEW.photo_id IS NULL AND NEW.album_id IS NULL) THEN
                            RAISE(ABORT, 'Like must target either photo or album')
                        WHEN (NEW.photo_id IS NOT NULL AND NEW.album_id IS NOT NULL) THEN
                            RAISE(ABORT, 'Like cannot target both photo and album')
                    END;
                END;
            """).run()
            
            // Unique constraint for photo likes
            try await sql.raw("""
                CREATE UNIQUE INDEX idx_likes_user_photo
                ON likes(user_id, photo_id)
                WHERE photo_id IS NOT NULL
            """).run()
            
            // Unique constraint for album likes
            try await sql.raw("""
                CREATE UNIQUE INDEX idx_likes_user_album
                ON likes(user_id, album_id)
                WHERE album_id IS NOT NULL
            """).run()
            
            // Indexes for counting
            try await sql.raw("""
                CREATE INDEX idx_likes_photo_id ON likes(photo_id)
                WHERE photo_id IS NOT NULL
            """).run()
            
            try await sql.raw("""
                CREATE INDEX idx_likes_album_id ON likes(album_id)
                WHERE album_id IS NOT NULL
            """).run()
        }
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("likes").delete()
    }
}
```

#### 1.6 Register Migrations

**File**: `Sources/App/configure.swift` (modification)

```swift
// Add to existing configure function
app.migrations.add(CreateUser())
app.migrations.add(UpdateAlbumWithOwner())
app.migrations.add(UpdatePhotoWithOwner())
app.migrations.add(CreateLike())

// Run migrations
try await app.autoMigrate()
```

**Test Command**:
```bash
swift test --filter MigrationTests
```

---

### Phase 2: Service Layer (TDD: Business Logic Tests)

**Goal**: Implement like business logic with self-like prevention

**File**: `Sources/App/Services/LikeService.swift`

```swift
import Vapor
import Fluent

struct LikeService {
    /// Create a like for a photo (idempotent)
    func likePhoto(photoId: UUID, userId: UUID, db: Database) async throws -> Like {
        // Verify photo exists and get owner
        guard let photo = try await Photo.find(photoId, on: db) else {
            throw Abort(.notFound, reason: "Photo not found")
        }
        
        // Prevent self-like
        guard photo.$owner.id != userId else {
            throw Abort(.badRequest, reason: "Cannot like your own content")
        }
        
        // Check if already liked (idempotent)
        if let existing = try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$photo.$id == photoId)
            .first() {
            return existing  // Already liked, return existing
        }
        
        // Create new like
        let like = Like(userId: userId, photoId: photoId)
        try await like.save(on: db)
        return like
    }
    
    /// Remove like from photo (idempotent)
    func unlikePhoto(photoId: UUID, userId: UUID, db: Database) async throws {
        // Delete if exists (idempotent - no error if not found)
        try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$photo.$id == photoId)
            .delete()
    }
    
    /// Get like count for photo
    func getPhotoLikeCount(photoId: UUID, db: Database) async throws -> Int {
        try await Like.query(on: db)
            .filter(\.$photo.$id == photoId)
            .count()
    }
    
    /// Check if user has liked photo
    func hasUserLikedPhoto(photoId: UUID, userId: UUID, db: Database) async throws -> Bool {
        let count = try await Like.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$photo.$id == photoId)
            .count()
        return count > 0
    }
    
    // Similar methods for albums: likeAlbum, unlikeAlbum, etc.
}
```

**Test File**: `Tests/AppTests/Services/LikeServiceTests.swift`

```swift
@testable import App
import XCTVapor

final class LikeServiceTests: XCTestCase {
    var app: Application!
    var service: LikeService!
    
    override func setUp() async throws {
        app = Application(.testing)
        try await configure(app)
        service = LikeService()
    }
    
    override func tearDown() async throws {
        app.shutdown()
    }
    
    func testLikePhoto_Success() async throws {
        // Arrange
        let user1 = User(username: "user1")
        let user2 = User(username: "user2")
        try await user1.save(on: app.db)
        try await user2.save(on: app.db)
        
        let album = Album(name: "Test", date: Date(), ownerId: user1.requireID())
        try await album.save(on: app.db)
        
        let photo = Photo(albumId: album.requireID(), ownerId: user1.requireID(), filePath: "/test.jpg")
        try await photo.save(on: app.db)
        
        // Act
        let like = try await service.likePhoto(
            photoId: photo.requireID(),
            userId: user2.requireID(),
            db: app.db
        )
        
        // Assert
        XCTAssertNotNil(like.id)
        XCTAssertEqual(like.$user.id, user2.id)
        XCTAssertEqual(like.$photo.id, photo.id)
    }
    
    func testLikePhoto_SelfLike_ThrowsError() async throws {
        // Arrange
        let user = User(username: "user1")
        try await user.save(on: app.db)
        
        let album = Album(name: "Test", date: Date(), ownerId: user.requireID())
        try await album.save(on: app.db)
        
        let photo = Photo(albumId: album.requireID(), ownerId: user.requireID(), filePath: "/test.jpg")
        try await photo.save(on: app.db)
        
        // Act & Assert
        await XCTAssertThrowsError(
            try await service.likePhoto(
                photoId: photo.requireID(),
                userId: user.requireID(),
                db: app.db
            )
        ) { error in
            XCTAssertEqual((error as? AbortError)?.status, .badRequest)
            XCTAssertTrue(error.localizedDescription.contains("Cannot like your own content"))
        }
    }
    
    func testLikePhoto_Idempotent() async throws {
        // Arrange: create users and photo
        // ...
        
        // Act: like twice
        let like1 = try await service.likePhoto(photoId: photoId, userId: userId, db: app.db)
        let like2 = try await service.likePhoto(photoId: photoId, userId: userId, db: app.db)
        
        // Assert: same like returned
        XCTAssertEqual(like1.id, like2.id)
        
        // Assert: only one like record in database
        let count = try await Like.query(on: app.db)
            .filter(\.$photo.$id == photoId)
            .count()
        XCTAssertEqual(count, 1)
    }
}
```

---

### Phase 3: API Layer (TDD: Controller Tests)

**File**: `Sources/App/Controllers/LikeController.swift`

```swift
import Vapor
import Fluent

struct LikeController: RouteCollection {
    let service = LikeService()
    
    func boot(routes: RoutesBuilder) throws {
        let likes = routes.grouped("api")
        
        // Require authentication for all like endpoints
        let protected = likes.grouped(UserSessionAuthenticator())
        
        // Photo likes
        protected.post("photos", ":photoId", "like", use: likePhoto)
        protected.delete("photos", ":photoId", "like", use: unlikePhoto)
        protected.get("photos", ":photoId", "likes", use: getPhotoLikes)
        protected.get("photos", ":photoId", "likers", use: getPhotoLikers)
        
        // Album likes
        protected.post("albums", ":albumId", "like", use: likeAlbum)
        protected.delete("albums", ":albumId", "like", use: unlikeAlbum)
        protected.get("albums", ":albumId", "likes", use: getAlbumLikes)
        protected.get("albums", ":albumId", "likers", use: getAlbumLikers)
    }
    
    func likePhoto(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        guard let photoId = req.parameters.get("photoId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid photo ID")
        }
        
        let like = try await service.likePhoto(
            photoId: photoId,
            userId: try user.requireID(),
            db: req.db
        )
        
        let likeCount = try await service.getPhotoLikeCount(photoId: photoId, db: req.db)
        
        return try await LikeResponse(
            id: like.requireID(),
            userId: user.requireID(),
            photoId: photoId,
            albumId: nil,
            createdAt: like.createdAt ?? Date(),
            likeCount: likeCount
        ).encodeResponse(status: .ok, for: req)
    }
    
    func unlikePhoto(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let photoId = req.parameters.get("photoId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid photo ID")
        }
        
        try await service.unlikePhoto(
            photoId: photoId,
            userId: try user.requireID(),
            db: req.db
        )
        
        return .noContent
    }
    
    func getPhotoLikes(req: Request) async throws -> LikeInfoResponse {
        let user = try req.auth.require(User.self)
        guard let photoId = req.parameters.get("photoId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid photo ID")
        }
        
        let count = try await service.getPhotoLikeCount(photoId: photoId, db: req.db)
        let isLiked = try await service.hasUserLikedPhoto(
            photoId: photoId,
            userId: try user.requireID(),
            db: req.db
        )
        
        return LikeInfoResponse(count: count, isLikedByCurrentUser: isLiked)
    }
    
    // Similar methods for album endpoints
}

// Response DTOs
struct LikeResponse: Content {
    let id: UUID
    let userId: UUID
    let photoId: UUID?
    let albumId: UUID?
    let createdAt: Date
    let likeCount: Int
}

struct LikeInfoResponse: Content {
    let count: Int
    let isLikedByCurrentUser: Bool
}
```

**Test File**: `Tests/AppTests/Controllers/LikeControllerTests.swift`

```swift
@testable import App
import XCTVapor

final class LikeControllerTests: XCTestCase {
    var app: Application!
    
    func testLikePhoto_Authenticated_ReturnsOK() async throws {
        // Arrange: create users, session, photo
        // ...
        
        // Act
        try app.test(.POST, "/api/photos/\(photoId)/like", beforeRequest: { req in
            req.headers.cookie = sessionCookie
        }, afterResponse: { res in
            // Assert
            XCTAssertEqual(res.status, .ok)
            let like = try res.content.decode(LikeResponse.self)
            XCTAssertNotNil(like.id)
            XCTAssertEqual(like.likeCount, 1)
        })
    }
    
    func testLikePhoto_Unauthenticated_Returns401() async throws {
        // Act & Assert
        try app.test(.POST, "/api/photos/\(photoId)/like", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
}
```

---

### Phase 4: Frontend Integration

**File**: `Public/js/likes.js` (new file)

```javascript
// Like button component
class LikeButton {
    constructor(photoId, albumId = null) {
        this.photoId = photoId;
        this.albumId = albumId;
        this.isPhoto = photoId !== null;
        this.button = null;
        this.countDisplay = null;
        this.isLiked = false;
        this.isProcessing = false;
    }
    
    render(container) {
        const wrapper = document.createElement('div');
        wrapper.className = 'like-widget';
        
        this.button = document.createElement('button');
        this.button.className = 'like-button';
        this.button.setAttribute('aria-label', 'Like');
        this.button.onclick = () => this.toggle();
        
        this.countDisplay = document.createElement('span');
        this.countDisplay.className = 'like-count';
        this.countDisplay.textContent = '0';
        
        wrapper.appendChild(this.button);
        wrapper.appendChild(this.countDisplay);
        container.appendChild(wrapper);
        
        // Initial fetch
        this.fetchLikeInfo();
        
        // Start polling
        this.startPolling();
    }
    
    async fetchLikeInfo() {
        const endpoint = this.isPhoto
            ? `/api/photos/${this.photoId}/likes`
            : `/api/albums/${this.albumId}/likes`;
        
        try {
            const response = await fetch(endpoint);
            if (response.ok) {
                const data = await response.json();
                this.updateUI(data.count, data.isLikedByCurrentUser);
            }
        } catch (error) {
            console.error('Failed to fetch like info:', error);
        }
    }
    
    async toggle() {
        if (this.isProcessing) return;
        this.isProcessing = true;
        this.button.disabled = true;
        
        const endpoint = this.isPhoto
            ? `/api/photos/${this.photoId}/like`
            : `/api/albums/${this.albumId}/like`;
        
        const method = this.isLiked ? 'DELETE' : 'POST';
        
        try {
            const response = await fetch(endpoint, { method });
            
            if (response.ok) {
                // Optimistic UI update
                this.isLiked = !this.isLiked;
                const newCount = parseInt(this.countDisplay.textContent) + (this.isLiked ? 1 : -1);
                this.updateUI(newCount, this.isLiked);
                
                // Fetch accurate count from server
                await this.fetchLikeInfo();
            } else if (response.status === 400) {
                const error = await response.json();
                alert(error.reason);  // e.g., "Cannot like your own content"
            }
        } catch (error) {
            console.error('Like toggle failed:', error);
            alert('Failed to update like. Please try again.');
        } finally {
            this.isProcessing = false;
            this.button.disabled = false;
        }
    }
    
    updateUI(count, isLiked) {
        this.isLiked = isLiked;
        this.countDisplay.textContent = count;
        this.button.classList.toggle('liked', isLiked);
        this.button.setAttribute('aria-label', isLiked ? 'Unlike' : 'Like');
    }
    
    startPolling() {
        setInterval(() => {
            if (!this.isProcessing) {
                this.fetchLikeInfo();
            }
        }, 2000);  // Poll every 2 seconds
    }
}

// Usage in albums.js or photos.js
// const likeButton = new LikeButton(photoId);
// likeButton.render(document.querySelector('.like-container'));
```

**File**: `Public/css/styles.css` (additions)

```css
.like-widget {
    display: inline-flex;
    align-items: center;
    gap: 8px;
}

.like-button {
    min-width: 44px;
    min-height: 44px;
    border: 2px solid #ccc;
    background: white;
    border-radius: 50%;
    cursor: pointer;
    transition: all 0.2s;
    position: relative;
}

.like-button::before {
    content: '♡';
    font-size: 20px;
}

.like-button.liked {
    background: #e91e63;
    border-color: #e91e63;
}

.like-button.liked::before {
    content: '♥';
    color: white;
}

.like-button:hover:not(:disabled) {
    transform: scale(1.1);
}

.like-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.like-count {
    font-size: 14px;
    color: #666;
    min-width: 20px;
}
```

---

## Testing Checklist

### Unit Tests
- [ ] User model validation (username length, characters)
- [ ] Like model XOR validation (photo XOR album)
- [ ] LikeService.likePhoto prevents self-like
- [ ] LikeService.likePhoto is idempotent
- [ ] LikeService.unlikePhoto is idempotent
- [ ] Like count calculation is accurate

### Integration Tests
- [ ] Database unique constraints prevent duplicate likes
- [ ] Cascade deletes work (user/photo/album deletion removes likes)
- [ ] Foreign key constraints enforced
- [ ] Indexes improve query performance

### API Tests
- [ ] POST /photos/:id/like returns 200 for valid like
- [ ] POST /photos/:id/like returns 400 for self-like
- [ ] POST /photos/:id/like returns 401 without auth
- [ ] DELETE /photos/:id/like returns 204
- [ ] GET /photos/:id/likes returns correct count and user status

### Frontend Tests (Manual)
- [ ] Like button toggles visual state on click
- [ ] Like count increments/decrements correctly
- [ ] Error message displayed for self-like attempt
- [ ] Button disabled during API call
- [ ] Like count polls and updates from server

---

## Performance Benchmarks

### Expected Metrics
- Like creation: <100ms p95
- Like count query: <50ms p95 (with 10K likes)
- API endpoint: <200ms p95 total latency
- Frontend polling: 2-second interval, negligible client CPU

### Load Testing
```bash
# Install vegeta (HTTP load testing tool)
brew install vegeta

# Test like endpoint
echo "POST http://localhost:8080/api/photos/{photoId}/like" | \
  vegeta attack -duration=30s -rate=50/s | \
  vegeta report

# Expected: >99% success rate, p95 <200ms
```

---

## Deployment Steps

1. **Run migrations**: `swift run App migrate`
2. **Run tests**: `swift test`
3. **Build**: `swift build -c release`
4. **Deploy**: `./Run serve --port 8080`

---

## Troubleshooting

### "Cannot like your own content" error persists
- Check that `photo.ownerId` is set correctly
- Verify session user ID matches expected value

### Like count not updating
- Verify polling loop is running (check browser console)
- Check API returns correct count
- Ensure indexes are created (`sqlite3 db.sqlite ".schema likes"`)

### Duplicate like error despite idempotent logic
- Check unique indexes are created correctly
- Verify service layer catch logic for constraint violations

---

## Next Steps

After completing basic like functionality:
1. Implement User Story 4 (view who liked - Priority P3)
2. Add like activity notifications (out of scope, future iteration)
3. Optimize with denormalized like counts if needed (YAGNI)
4. Add rate limiting to prevent abuse (optional)

---

**Phase 1 Complete** - Ready for `/speckit.tasks` to break down implementation into actionable tasks.
