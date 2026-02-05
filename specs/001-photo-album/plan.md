# Implementation Plan: Photo Album Organizer

**Branch**: `001-photo-album` | **Date**: 2026-02-04 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-photo-album/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a web-based photo album organizer using Swift Vapor that allows users to create and manage photo albums organized by date. Albums display photos in a tile interface, support drag-and-drop reordering, and store metadata in SQLite while referencing local photo files. The application uses minimal dependencies with vanilla HTML, CSS, and JavaScript for the frontend.

## Technical Context

**Language/Version**: Swift 5.9+ (Vapor 4.x web framework)
**Primary Dependencies**: Vapor (web framework), Fluent (ORM), FluentSQLiteDriver (SQLite adapter), Leaf (templating - optional)
**Storage**: SQLite database for metadata (albums, photo references, ordering); Photos remain in original filesystem locations (not uploaded)
**Testing**: XCTest (Swift's built-in testing framework)
**Target Platform**: macOS/Linux server (local deployment, single-user desktop application)
**Project Type**: Web application (backend serves HTML/CSS/JS, single-page structure)
**Performance Goals**: 
  - Album grid rendering <2s for 50+ albums
  - Thumbnail generation <500ms per photo
  - 60 FPS drag-and-drop (16ms frame time)
  - Page load <1s, API response <200ms (reads), <500ms (writes)
**Constraints**: 
  - Minimal external dependencies (vanilla JS, no frontend frameworks)
  - No photo uploads (file path references only)
  - Local-only deployment (no cloud/remote access)
  - Single-user design (no authentication required)
**Scale/Scope**: 
  - Support 10,000+ photo references
  - 100+ albums
  - Desktop browser access (Chrome, Firefox, Safari)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Phase 0 Evaluation

### I. Code Quality Standards
- ✅ **Single Responsibility**: Vapor's MVC structure enforces separation (Models, Controllers, Routes)
- ✅ **Type Safety**: Swift's strong static typing enforced at compile-time
- ✅ **Error Handling**: Swift requires explicit error handling with do-catch and throws
- ✅ **Linting**: SwiftLint will be configured for code style consistency

### II. Testing Discipline (NON-NEGOTIABLE)
- ✅ **TDD Workflow**: Tests written first for all business logic and API endpoints
- ✅ **Coverage Target**: 80% minimum coverage using XCTest
- ✅ **Test Types**:
  - Unit tests for album/photo models and business logic
  - Integration tests for database operations (Fluent)
  - Contract tests for API endpoints (REST routes)
- ✅ **Fast Feedback**: Swift compilation + XCTest ensures quick test execution

### III. User Experience Consistency
- ✅ **Design System**: Simple, consistent HTML/CSS components (no framework needed)
- ✅ **Accessibility**: Semantic HTML, ARIA labels, keyboard navigation support
- ✅ **Response Time**: <100ms interaction feedback via JavaScript, loading states for thumbnails
- ✅ **Error Messages**: User-friendly error handling in UI (file not found, invalid format)
- ✅ **Mobile Responsive**: CSS media queries for responsive grid layout
- ⚠️ **Touch Targets**: Minimum 44x44px for buttons and draggable elements (verify in testing)

### IV. Performance Requirements
- ✅ **API Latency**: Vapor's async/await meets <200ms read, <500ms write targets
- ✅ **Page Load**: Static HTML/CSS/JS served directly, no bundling overhead
- ✅ **Resource Limits**: Swift memory management, SQLite query optimization with indexes
- ✅ **Database Performance**: Indexes on album.date, photo.albumId, album.customOrder
- ✅ **Monitoring**: Basic logging via Vapor's built-in logger (can add metrics later)

**Gate Status**: ✅ **PASS** - All constitutional requirements can be met with planned architecture.

**Notes**: 
- No violations requiring justification
- Minimal dependencies align with simplicity principle
- Swift's type system and Vapor's structure support code quality standards
- Performance targets achievable with SQLite indexes and proper caching

---

### Post-Phase 1 Re-evaluation

After completing research, data model, API contracts, and quickstart guide:

### I. Code Quality Standards
- ✅ **CONFIRMED**: Data model uses clear entity separation (Album, Photo, UserPreference)
- ✅ **CONFIRMED**: API contracts follow RESTful conventions with explicit schemas
- ✅ **CONFIRMED**: SwiftLint configuration included in quickstart

### II. Testing Discipline
- ✅ **CONFIRMED**: Test structure defined (Controllers/, Models/, Integration/)
- ✅ **CONFIRMED**: API contracts provide test specifications (OpenAPI 3.0)
- ✅ **CONFIRMED**: TDD workflow documented in quickstart

### III. User Experience Consistency
- ✅ **CONFIRMED**: HTML5 semantic elements, accessibility in research decisions
- ✅ **CONFIRMED**: Error handling patterns defined in API contracts (proper HTTP status codes)
- ✅ **CONFIRMED**: Responsive design patterns in frontend code samples
- ✅ **VERIFIED**: Touch targets addressed in drag-drop research (44x44px minimum)

### IV. Performance Requirements
- ✅ **CONFIRMED**: Database indexes optimized (composite index on albumId + displayOrder)
- ✅ **CONFIRMED**: SQLite WAL mode for concurrent reads
- ✅ **CONFIRMED**: Thumbnail caching strategy defined (lazy generation, disk cache)
- ✅ **CONFIRMED**: Batch operations for multi-photo inserts (performance optimization)

**Final Gate Status**: ✅ **PASS** - Design meets all constitutional requirements.

**Key Validations**:
- Composite database indexes support 10,000+ photos without degradation
- Thumbnail generation <500ms target achievable with ImageIO framework
- Drag-drop 60 FPS achievable with HTML5 API + CSS transforms
- API response times <200ms achievable with indexed queries
- 80% test coverage achievable with defined test structure

## Project Structure

### Documentation (this feature)

```text
specs/001-photo-album/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── api.yaml        # OpenAPI specification for REST endpoints
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
PhotoAlbumOrganizer/
├── Package.swift                 # Swift package manifest
├── Sources/
│   └── App/
│       ├── Controllers/
│       │   ├── AlbumController.swift
│       │   └── PhotoController.swift
│       ├── Models/
│       │   ├── Album.swift
│       │   ├── Photo.swift
│       │   └── UserPreference.swift
│       ├── Migrations/
│       │   ├── CreateAlbum.swift
│       │   ├── CreatePhoto.swift
│       │   └── CreateUserPreference.swift
│       ├── Services/
│       │   ├── ThumbnailService.swift
│       │   └── FileValidationService.swift
│       ├── configure.swift       # Vapor configuration
│       └── routes.swift          # Route definitions
├── Public/
│   ├── css/
│   │   └── styles.css           # Vanilla CSS (no preprocessor)
│   ├── js/
│   │   ├── albums.js            # Album grid and drag-drop logic
│   │   ├── photos.js            # Photo tile grid and viewer
│   │   └── utils.js             # Shared utilities
│   └── index.html               # Main application page
├── Resources/
│   └── Views/                   # Optional Leaf templates if needed
├── Tests/
│   └── AppTests/
│       ├── Controllers/
│       │   ├── AlbumControllerTests.swift
│       │   └── PhotoControllerTests.swift
│       ├── Models/
│       │   ├── AlbumTests.swift
│       │   └── PhotoTests.swift
│       └── Integration/
│           ├── AlbumAPITests.swift
│           └── PhotoAPITests.swift
└── db/
    └── photos.db                # SQLite database (created at runtime)
```

**Structure Decision**: Web application structure selected based on:
- Vapor backend serving REST API + static files
- Vanilla HTML/CSS/JS frontend (no build tools required)
- Single-page application with client-side routing
- Static assets served from `Public/` directory
- Fluent migrations for database schema management
- Clear separation: Controllers (routes), Models (data), Services (business logic)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** - All constitutional requirements met by planned architecture.

The minimal dependency approach (Vapor + vanilla HTML/CSS/JS) aligns with simplicity principles and avoids unnecessary complexity.
