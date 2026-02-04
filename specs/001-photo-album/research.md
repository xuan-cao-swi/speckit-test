# Research: Photo Album Organizer

**Phase**: 0 - Outline & Research  
**Date**: 2026-02-04  
**Purpose**: Resolve technical unknowns and establish best practices for implementation

## Technical Context Review

All technical context items were specified in the initial planning request. No NEEDS CLARIFICATION items to resolve.

**Confirmed Decisions**:
- Language: Swift 5.9+ with Vapor 4.x
- Frontend: Vanilla HTML, CSS, JavaScript (no frameworks)
- Storage: SQLite via Fluent ORM
- Testing: XCTest
- Deployment: Local server (macOS/Linux)

## Research Tasks Completed

### 1. Vapor 4 Best Practices for File-Based Applications

**Research Question**: How to structure a Vapor application that references local files without uploads?

**Findings**:
- **File Path Storage**: Store absolute file paths in SQLite as TEXT fields
- **File Validation**: Use `FileManager` from Foundation to check file existence and read metadata
- **Security Consideration**: Validate file paths are within allowed directories to prevent path traversal attacks
- **File Serving**: For thumbnails, generate once and cache in `Public/thumbnails/` directory
- **Error Handling**: Gracefully handle missing files with 404 responses and client-side placeholders

**Decision**: 
- Store absolute file paths in `Photo.filePath` column
- Create `FileValidationService` to verify files exist and are valid image formats
- Generate thumbnails on-demand and cache with original filename hash
- Serve thumbnails via static file serving from `Public/thumbnails/`

**Rationale**: Avoids file duplication, maintains user's original file organization, reduces storage requirements.

---

### 2. Swift Image Processing for Thumbnails

**Research Question**: What are the minimal dependencies for generating thumbnails in Swift?

**Findings**:
- **CoreGraphics** (macOS/iOS): Built-in, no dependencies required
- **ImageIO Framework**: Efficient for reading image metadata and generating thumbnails
- **Supported Formats**: JPEG, PNG, HEIC, GIF, WebP (with macOS 11+)
- **Thumbnail Generation**: `CGImageSourceCreateThumbnailAtIndex` provides efficient thumbnail creation

**Decision**:
- Use ImageIO framework for thumbnail generation (built-in, no external dependencies)
- Generate thumbnails at 200x200px for grid tiles (configurable in UserPreference)
- Cache thumbnails as JPEG with 85% quality for size/quality balance
- Use SHA256 hash of file path as thumbnail filename to avoid collisions

**Rationale**: Zero external dependencies, efficient, supports all required formats, maintains minimal dependency constraint.

**Alternative Considered**: SwiftGD or ImageMagick bindings
**Rejected Because**: Introduces external C dependencies, violates minimal dependencies requirement.

---

### 3. Vanilla JavaScript Drag-and-Drop Best Practices

**Research Question**: How to implement smooth 60 FPS drag-and-drop without frameworks?

**Findings**:
- **HTML5 Drag and Drop API**: Native browser support, event-driven
- **Events**: `dragstart`, `dragover`, `drop`, `dragend`
- **Visual Feedback**: Use `dataTransfer.effectAllowed` and CSS classes for drag states
- **Performance**: Use `requestAnimationFrame` for smooth position updates
- **Touch Support**: Requires separate touch event handling (`touchstart`, `touchmove`, `touchend`)
- **Persistence**: Send PATCH request to server after drop to update `customOrder` field

**Decision**:
- Implement HTML5 Drag API for desktop browsers
- Add touch event polyfill for mobile/tablet support
- Use CSS transforms (not position changes) for smooth visual feedback
- Debounce server updates during rapid reordering (500ms delay after last drop)
- Optimistic UI update with rollback on server error

**Rationale**: Native API provides best performance, no library needed, progressive enhancement for touch.

**Alternative Considered**: SortableJS library
**Rejected Because**: Violates minimal dependencies constraint, vanilla JS sufficient for this use case.

---

### 4. SQLite Performance Optimization for Photo Metadata

**Research Question**: What indexes and schema optimizations are needed for 10,000+ photos?

**Findings**:
- **Index Strategy**: Create indexes on frequently queried columns
  - `albums(date)` - for chronological sorting
  - `albums(customOrder)` - for manual ordering
  - `photos(albumId)` - for filtering photos by album
  - `photos(albumId, displayOrder)` - composite index for sorted photo retrieval
- **Query Patterns**: Use `SELECT * FROM photos WHERE albumId = ? ORDER BY displayOrder` frequently
- **Connection Pooling**: Vapor handles SQLite connections via EventLoopFuture
- **Write Optimization**: Batch inserts when adding multiple photos (single transaction)

**Decision**:
- Create composite index on `(albumId, displayOrder)` for photo queries
- Single index on `albums.date` for date-based sorting
- Single index on `albums.customOrder` for manual ordering
- Use Fluent's batch insert for multiple photos
- Set SQLite `PRAGMA journal_mode=WAL` for better concurrent read performance

**Rationale**: Optimizes common query patterns, supports 10,000+ photos without performance degradation.

---

### 5. Fluent ORM Patterns for Swift Vapor

**Research Question**: Best practices for Fluent models, migrations, and relationships?

**Findings**:
- **Model Structure**: Use `final class` with `@field` property wrappers
- **Relationships**: `@parent` for many-to-one (Photo → Album), `@children` for one-to-many (Album → Photos)
- **Migrations**: Separate migration file for each model, explicit `id` and timestamp fields
- **Soft Deletes**: Use `@timestamp(on: .delete)` if needed (not required for this app)
- **Validation**: Implement `validations()` method for model-level constraints

**Decision**:
- Create three models: `Album`, `Photo`, `UserPreference`
- Use Fluent relationships: `Photo.album` (@parent), `Album.photos` (@children)
- Implement `validations()` for required fields (album name, photo filePath)
- Create separate migration files for each model with proper foreign key constraints
- Add `updatedAt` timestamp to track changes for sync/cache invalidation

**Rationale**: Follows Fluent conventions, provides type-safe database access, enables relationship queries.

---

### 6. REST API Design for Album/Photo Management

**Research Question**: What REST endpoints are needed for all user stories?

**Findings**:
- **Resource-Based URLs**: `/api/albums`, `/api/albums/:id`, `/api/photos`, etc.
- **HTTP Methods**: GET (read), POST (create), PATCH (update), DELETE (delete)
- **Response Format**: JSON for API endpoints, HTML for page routes
- **Error Handling**: Use HTTP status codes (400, 404, 500) with JSON error bodies
- **Pagination**: Consider for large photo lists (use `limit` and `offset` query params)

**Decision**:
- **Albums**:
  - `GET /api/albums` - List all albums with sorting
  - `POST /api/albums` - Create new album
  - `GET /api/albums/:id` - Get album details
  - `PATCH /api/albums/:id` - Update album (name, date, customOrder)
  - `DELETE /api/albums/:id` - Delete album
  - `PATCH /api/albums/reorder` - Batch update customOrder for multiple albums
- **Photos**:
  - `GET /api/albums/:albumId/photos` - List photos in album
  - `POST /api/albums/:albumId/photos` - Add photos to album (batch)
  - `DELETE /api/photos/:id` - Remove photo from album
  - `GET /api/photos/:id/thumbnail` - Get cached thumbnail
- **Preferences**:
  - `GET /api/preferences` - Get user preferences
  - `PATCH /api/preferences` - Update preferences

**Rationale**: RESTful design, clear resource hierarchy, supports all user stories, enables batch operations for performance.

---

### 7. Frontend State Management Without Frameworks

**Research Question**: How to manage application state in vanilla JavaScript?

**Findings**:
- **Module Pattern**: Use ES6 modules for encapsulation
- **State Object**: Single source of truth object for current app state
- **Event System**: Custom event system for component communication
- **DOM Updates**: Manual DOM manipulation with `innerHTML` or `createElement`
- **API Integration**: `fetch()` API for async HTTP requests

**Decision**:
- Create `AppState` object holding:
  - `currentView`: 'albums' | 'album-detail' | 'photo-viewer'
  - `albums`: Array of album objects
  - `currentAlbum`: Currently viewed album
  - `currentPhotoIndex`: Index in photo viewer
- Use `render()` functions for each view that read from AppState
- Implement simple pub/sub pattern for state change notifications
- Store state in memory only (reload from server on page refresh)

**Rationale**: Keeps code simple, no framework overhead, explicit control flow, sufficient for single-page app.

**Alternative Considered**: LocalStorage for state persistence
**Rejected Because**: Server is source of truth, added complexity unnecessary for this use case.

---

## Summary of Technical Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **File Handling** | Store absolute paths, validate with FileManager | Minimal storage, preserves user organization |
| **Thumbnails** | ImageIO framework, 200x200px JPEG cache | Zero dependencies, efficient, all formats supported |
| **Drag-Drop** | HTML5 Drag API + touch polyfill | Native performance, no library needed |
| **Database** | Composite indexes, WAL mode, batch inserts | Supports 10,000+ photos, optimizes queries |
| **ORM Patterns** | Fluent relationships, separate migrations | Type-safe, follows conventions |
| **API Design** | RESTful with batch operations | Clear resource model, performance optimized |
| **Frontend State** | Simple AppState object + pub/sub | No framework, explicit, sufficient complexity |

## Open Questions / Future Enhancements

1. **EXIF Data Reading**: Not required for MVP, but could extract date from photo metadata in future
2. **Search Functionality**: Out of scope initially, would require full-text search index
3. **Export/Import**: Could add JSON export of album metadata for backup
4. **Multi-user Support**: Would require authentication and user-scoped queries

All core functionality can be implemented with decisions above. No blocking unknowns remain.
