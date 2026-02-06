# Implementation Plan: Social Media Likes for Photos and Albums

**Branch**: `002-photo-likes` | **Date**: 2026-02-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-photo-likes/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add social media like functionality to the photo album application, allowing users to like/unlike photos and albums created by other users. The system tracks like counts, displays them on content, prevents self-liking, and optionally shows who liked content. Requires user authentication to identify who is liking content and enforce ownership rules.

## Technical Context

**Language/Version**: Swift 5.9+ (Vapor 4.x web framework)
**Primary Dependencies**: Vapor (web framework), Fluent (ORM), FluentSQLiteDriver (SQLite adapter), NEEDS CLARIFICATION: user authentication library
**Storage**: SQLite database for like relationships (user-photo, user-album)
**Testing**: XCTest (Swift's built-in testing framework)
**Target Platform**: macOS/Linux server (local deployment, multi-user environment)
**Project Type**: Web application (extends existing 001-photo-album project)
**Performance Goals**: 
  - Like/unlike action <1s for visual feedback
  - Like count display/update <2s
  - API response <200ms (reads), <500ms (writes)
**Constraints**: 
  - Minimal external dependencies (vanilla JS, no frontend frameworks)
  - Must integrate with existing photo album data model
  - Prevent self-likes (business rule enforcement)
  - Handle concurrent like operations without race conditions
**Scale/Scope**: 
  - Support 100 concurrent users
  - Handle thousands of likes per photo/album
  - Real-time or near-real-time like count updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Phase 0 Evaluation

### I. Code Quality Standards
- ✅ **Single Responsibility**: Like functionality will be isolated in dedicated controller and models
- ✅ **Type Safety**: Swift's strong static typing enforced at compile-time
- ✅ **Error Handling**: Swift requires explicit error handling with do-catch and throws
- ✅ **Linting**: SwiftLint already configured in base project

### II. Testing Discipline (NON-NEGOTIABLE)
- ✅ **TDD Workflow**: Tests written first for like/unlike logic, constraints, and API endpoints
- ✅ **Coverage Target**: 80% minimum coverage using XCTest
- ✅ **Test Types**:
  - Unit tests for like business logic (prevent self-like, toggle like/unlike)
  - Integration tests for database operations (like creation, deletion, counting)
  - Contract tests for API endpoints (POST /photos/:id/like, GET /photos/:id/likes)
- ✅ **Fast Feedback**: XCTest execution <1 minute for unit tests

### III. User Experience Consistency
- ✅ **Design System**: Extend existing vanilla HTML/CSS with like button component
- ✅ **Accessibility**: Accessible like button (ARIA labels, keyboard support)
- ✅ **Response Time**: <1s visual feedback for like action (loading state), <2s count update
- ✅ **Error Messages**: User-friendly error messages (e.g., "You cannot like your own content")
- ✅ **Consistency**: Like button behavior consistent across photos and albums
- ✅ **Mobile Responsive**: Like button meets 44x44px touch target minimum

### IV. Performance Requirements
- ✅ **API Latency**: <200ms for like count retrieval, <500ms for like/unlike operations
- ✅ **Database Performance**: Indexes on (userId, photoId), (userId, albumId) for fast lookup
- ✅ **Concurrency**: Database constraints prevent duplicate likes (unique index)
- ⚠️ **NEEDS CLARIFICATION**: Authentication/user identification mechanism (session, JWT, basic auth?)
- ⚠️ **NEEDS CLARIFICATION**: Real-time update strategy (polling, WebSocket, server-sent events?)

**Gate Status**: ⚠️ **CONDITIONAL PASS** - Architecture meets constitution requirements, but requires clarification on:
1. User authentication mechanism (blocking issue)
2. Real-time update implementation (design decision)

---

### Post-Phase 1 Re-evaluation

After completing research, data model, API contracts, and quickstart guide:

### I. Code Quality Standards
- ✅ **CONFIRMED**: Like functionality isolated in dedicated LikeController, LikeService, Like model
- ✅ **CONFIRMED**: Swift's type safety enforced throughout (UUID types, enums for formats)
- ✅ **CONFIRMED**: Error handling with explicit Abort errors and meaningful messages
- ✅ **CONFIRMED**: SwiftLint configuration already in base project

### II. Testing Discipline (NON-NEGOTIABLE)
- ✅ **CONFIRMED**: TDD structure defined in quickstart (tests before implementation)
- ✅ **CONFIRMED**: Test coverage targets: LikeServiceTests, LikeControllerTests, integration tests
- ✅ **CONFIRMED**: API contracts provide explicit test specifications (OpenAPI 3.0)
- ✅ **CONFIRMED**: Test checklist in quickstart ensures comprehensive coverage

### III. User Experience Consistency
- ✅ **CONFIRMED**: Like button component follows 44x44px touch target minimum
- ✅ **CONFIRMED**: Accessibility: ARIA labels for like button state ("Liked"/"Unlike")
- ✅ **CONFIRMED**: Response time: <1s visual feedback (optimistic UI), <2s count update
- ✅ **CONFIRMED**: Error messages user-friendly ("Cannot like your own content")
- ✅ **CONFIRMED**: Consistent behavior across photos and albums
- ✅ **CONFIRMED**: CSS responsive design with proper mobile support

### IV. Performance Requirements
- ✅ **CONFIRMED**: API latency targets met (<200ms reads, <500ms writes)
- ✅ **CONFIRMED**: Database indexes on all query paths (userId+photoId, userId+albumId, photoId, albumId)
- ✅ **CONFIRMED**: Polling strategy (2s interval) handles 100 concurrent users (50 req/s)
- ✅ **CONFIRMED**: Query performance benchmarks defined (<50ms COUNT with indexes)
- ✅ **RESOLVED**: User authentication via simple session-based cookies (no external library)
- ✅ **RESOLVED**: Real-time updates via HTTP polling (vanilla JS, no WebSocket library)

**Final Gate Status**: ✅ **PASS** - All constitutional requirements satisfied. Research resolved all NEEDS CLARIFICATION items with minimal-dependency solutions.

## Project Structure

### Documentation (this feature)

```text
specs/002-photo-likes/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── api.yaml         # OpenAPI specification for like endpoints
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Sources/App/
├── Models/
│   ├── Album.swift          # EXISTING - will add like relationship
│   ├── Photo.swift          # EXISTING - will add like relationship
│   ├── UserPreference.swift # EXISTING - no changes
│   ├── User.swift           # NEW - user authentication/identification
│   └── Like.swift           # NEW - like entity (polymorphic: photo or album)
├── Controllers/
│   ├── AlbumController.swift  # EXISTING - will add like count to responses
│   ├── PhotoController.swift  # EXISTING - will add like count to responses
│   ├── PreferenceController.swift # EXISTING - no changes
│   ├── LikeController.swift   # NEW - like/unlike endpoints
│   └── UserController.swift   # NEW - basic user endpoints (if needed)
├── Services/
│   ├── FileValidationService.swift # EXISTING - no changes
│   ├── ThumbnailService.swift      # EXISTING - no changes
│   └── LikeService.swift           # NEW - like business logic (prevent self-like)
├── Migrations/
│   ├── CreateAlbum.swift          # EXISTING
│   ├── CreatePhoto.swift          # EXISTING
│   ├── CreateUserPreference.swift # EXISTING
│   ├── CreateUser.swift           # NEW - user table
│   └── CreateLike.swift           # NEW - like table with constraints
├── configure.swift      # EXISTING - will add like routes and migrations
├── routes.swift         # EXISTING - will add like endpoints
└── main.swift           # EXISTING - no changes

Tests/AppTests/
├── Models/
│   ├── AlbumTests.swift          # EXISTING - may add like count tests
│   ├── PhotoTests.swift          # EXISTING - may add like count tests
│   ├── UserTests.swift           # NEW - user model tests
│   └── LikeTests.swift           # NEW - like model tests
├── Controllers/
│   ├── AlbumControllerTests.swift      # EXISTING - update for like counts
│   ├── PhotoControllerTests.swift      # EXISTING - update for like counts
│   ├── PreferenceControllerTests.swift # EXISTING - no changes
│   └── LikeControllerTests.swift       # NEW - like/unlike API tests
├── Services/
│   ├── FileValidationServiceTests.swift # EXISTING - no changes
│   ├── ThumbnailServiceTests.swift      # EXISTING - no changes
│   └── LikeServiceTests.swift           # NEW - self-like prevention tests
└── Integration/
    └── IntegrationTests.swift  # EXISTING - will add like integration tests

Public/
├── js/
│   ├── albums.js     # EXISTING - will add like button functionality
│   ├── photos.js     # EXISTING - will add like button functionality
│   └── utils.js      # EXISTING - may add like utility functions
├── css/
│   └── styles.css    # EXISTING - will add like button styles
├── thumbnails/       # EXISTING - no changes
└── index.html        # EXISTING - may add like button UI components
```

**Structure Decision**: Extending existing single-project web application structure from 001-photo-album. Adding new User and Like models, dedicated LikeController and LikeService for social functionality. Following established MVC pattern with Models, Controllers, Services separation.

## Complexity Tracking

> **No complexity violations** - The like feature integrates cleanly into existing architecture without violating constitutional principles. User authentication is a prerequisite dependency that must be resolved in Phase 0 research.
