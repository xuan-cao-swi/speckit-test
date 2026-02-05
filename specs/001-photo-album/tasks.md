---
description: "Task list for Photo Album Organizer implementation"
---

# Tasks: Photo Album Organizer

**Input**: Design documents from `/specs/001-photo-album/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: Following TDD (Test-Driven Development) - tests MUST be written first, approved, fail, then implementation makes them pass.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- Backend: `Sources/App/` (Models, Controllers, Migrations, Services)
- Frontend: `Public/` (html, css, js)
- Tests: `Tests/AppTests/` (Controllers, Models, Integration)
- Database: `db/photos.db` (created at runtime)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project using `vapor new PhotoAlbumOrganizer` or Swift Package Manager
- [x] T002 Configure Package.swift with dependencies (Vapor 4.x, Fluent, FluentSQLiteDriver)
- [x] T003 [P] Create directory structure: Sources/App/{Controllers,Models,Migrations,Services}
- [x] T004 [P] Create directory structure: Public/{css,js,thumbnails}
- [x] T005 [P] Create directory structure: Tests/AppTests/{Controllers,Models,Integration}
- [x] T006 [P] Create directory structure: db/ for SQLite database
- [x] T007 Create Sources/App/main.swift with Vapor application entry point
- [x] T008 Create Sources/App/configure.swift with database and middleware setup
- [x] T009 Create Sources/App/routes.swift with initial route structure
- [x] T010 [P] Configure SwiftLint with .swiftlint.yml for code quality enforcement
- [x] T011 [P] Create .gitignore for Swift/Vapor project (db/*.db, .build/, Package.resolved)
- [x] T012 Run `swift build` to verify project setup and dependencies

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T013 Create Album model in Sources/App/Models/Album.swift with all fields per data-model.md
- [x] T014 Create Photo model in Sources/App/Models/Photo.swift with all fields and relationships
- [x] T015 Create UserPreference model in Sources/App/Models/UserPreference.swift as singleton
- [x] T016 Create CreateAlbum migration in Sources/App/Migrations/CreateAlbum.swift with indexes
- [x] T017 Create CreatePhoto migration in Sources/App/Migrations/CreatePhoto.swift with composite index
- [x] T018 Create CreateUserPreference migration in Sources/App/Migrations/CreateUserPreference.swift
- [x] T019 Register migrations in configure.swift and configure SQLite with WAL mode
- [x] T020 Create FileValidationService in Sources/App/Services/FileValidationService.swift for image validation
- [x] T021 Create ThumbnailService in Sources/App/Services/ThumbnailService.swift using ImageIO framework
- [x] T022 Configure static file serving middleware in configure.swift for Public/ directory
- [x] T023 Create Public/index.html with semantic HTML structure and accessibility attributes
- [x] T024 Create Public/css/styles.css with responsive grid layout and mobile-first design
- [x] T025 Create Public/js/utils.js with shared utilities (API fetch helpers, error handling)
- [x] T026 Run migrations with `swift run` to create database schema
- [x] T027 Verify database schema using `sqlite3 db/photos.db .schema`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View and Browse Photo Albums (Priority: P1) 🎯 MVP

**Goal**: Display all albums on main page and allow users to browse photos within albums

**Independent Test**: Launch app, verify albums display with covers, click album to see photos, return to album list

### Tests for User Story 1 (TDD - Write These FIRST) ⚠️

> **CRITICAL: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T028 [P] [US1] Create AlbumTests.swift - test Album model validation (name required, date valid)
- [x] T029 [P] [US1] Create PhotoTests.swift - test Photo model validation and relationships
- [x] T030 [US1] Create AlbumControllerTests.swift - test GET /api/albums returns empty array initially
- [x] T031 [US1] Create AlbumControllerTests.swift - test GET /api/albums returns albums sorted by date
- [x] T032 [US1] Create AlbumControllerTests.swift - test GET /api/albums/:id returns album details
- [x] T033 [US1] Create PhotoControllerTests.swift - test GET /api/albums/:id/photos returns photos sorted by displayOrder
- [x] T034 [US1] Create integration test - verify album with photos returns correct photoCount
- [x] T035 [US1] Run tests with `swift test` - verify ALL tests FAIL (red phase)

### Implementation for User Story 1

- [x] T036 [P] [US1] Implement AlbumController.index in Sources/App/Controllers/AlbumController.swift (GET /api/albums)
- [x] T037 [P] [US1] Implement AlbumController.show in Sources/App/Controllers/AlbumController.swift (GET /api/albums/:id)
- [x] T038 [P] [US1] Implement PhotoController.index in Sources/App/Controllers/PhotoController.swift (GET /api/albums/:id/photos)
- [x] T039 [US1] Register album routes in routes.swift (api.get("albums"), api.get("albums", ":albumId"))
- [x] T040 [US1] Register photo routes in routes.swift (api.get("albums", ":albumId", "photos"))
- [x] T041 [US1] Add computed photoCount property to Album model (count photos relationship)
- [x] T042 [US1] Create AppState object in Public/js/albums.js with albums array and currentView state
- [x] T043 [US1] Implement loadAlbums() function in Public/js/albums.js to fetch from GET /api/albums
- [x] T044 [US1] Implement renderAlbums() function in Public/js/albums.js to display album grid
- [x] T045 [US1] Add album card click handler to navigate to album detail view
- [x] T046 [US1] Create Public/js/photos.js for photo tile grid rendering
- [x] T047 [US1] Implement loadPhotos(albumId) function to fetch from GET /api/albums/:id/photos
- [x] T048 [US1] Implement renderPhotoGrid() function with responsive tile layout
- [x] T049 [US1] Add back button handler to return from album detail to album list
- [x] T050 [US1] Style album grid with CSS (grid layout, hover states, cover images)
- [x] T051 [US1] Style photo tiles with CSS (responsive grid, aspect ratio preservation)
- [x] T052 [US1] Add loading states and error handling UI for failed API calls
- [x] T053 [US1] Run tests with `swift test` - verify ALL tests PASS (green phase)
- [x] T054 [US1] Refactor code for clarity and remove duplication (refactor phase)
- [x] T055 [US1] Manual testing: Launch app, verify albums display and navigation works

**Checkpoint**: User Story 1 complete - users can view and browse albums independently

---

## Phase 4: User Story 2 - Create and Manage Albums (Priority: P2)

**Goal**: Enable users to create, edit, and delete albums

**Independent Test**: Create album with name and date, verify it appears in correct order, edit album, delete album

### Tests for User Story 2 (TDD - Write These FIRST) ⚠️

- [x] T056 [P] [US2] Create test for POST /api/albums - verify album creation with valid data
- [x] T057 [P] [US2] Create test for POST /api/albums - verify 400 error with invalid data (empty name)
- [x] T058 [P] [US2] Create test for PATCH /api/albums/:id - verify album update
- [x] T059 [P] [US2] Create test for DELETE /api/albums/:id - verify album deletion (204 response)
- [x] T060 [US2] Create integration test - verify deleting album cascades to photos table
- [x] T061 [US2] Run tests - verify ALL new tests FAIL (red phase)

### Implementation for User Story 2

- [x] T062 [P] [US2] Implement AlbumController.create in Sources/App/Controllers/AlbumController.swift (POST /api/albums)
- [x] T063 [P] [US2] Implement AlbumController.update in Sources/App/Controllers/AlbumController.swift (PATCH /api/albums/:id)
- [x] T064 [P] [US2] Implement AlbumController.delete in Sources/App/Controllers/AlbumController.swift (DELETE /api/albums/:id)
- [x] T065 [US2] Add validation in AlbumController.create for name length (1-255 chars)
- [x] T066 [US2] Add validation in AlbumController.create for valid date format
- [x] T067 [US2] Register create/update/delete routes in routes.swift
- [x] T068 [US2] Create album creation form modal in Public/index.html
- [x] T069 [US2] Implement createAlbumModal() function in Public/js/albums.js
- [x] T070 [US2] Implement submitCreateAlbum() function to POST /api/albums
- [x] T071 [US2] Implement editAlbumModal(albumId) function for edit form
- [x] T072 [US2] Implement submitEditAlbum(albumId) function to PATCH /api/albums/:id
- [x] T073 [US2] Implement deleteAlbum(albumId) function with confirmation dialog
- [x] T074 [US2] Add optimistic UI updates (show album immediately, rollback on error)
- [x] T075 [US2] Add form validation UI (highlight errors, show messages)
- [x] T076 [US2] Style modal forms with CSS (centered, accessible, responsive)
- [x] T077 [US2] Add keyboard shortcuts (Escape to close modal, Enter to submit)
- [ ] T078 [US2] Run tests - verify ALL tests PASS (green phase)
- [ ] T079 [US2] Refactor form handling code to reduce duplication
- [ ] T080 [US2] Manual testing: Create, edit, delete albums, verify database persistence

**Checkpoint**: User Story 2 complete - users can fully manage albums

---

## Phase 5: User Story 4 - Add Photos to Albums (Priority: P2)

**Goal**: Enable users to add and remove photos from albums

**Independent Test**: Add photos via file picker, verify thumbnails display, remove photo from album

**Note**: Implemented before US3 (drag-drop) as it's higher priority and US3 depends on having albums to reorder

### Tests for User Story 4 (TDD - Write These FIRST) ⚠️

- [x] T081 [P] [US4] Create test for POST /api/albums/:id/photos - verify batch photo addition
- [x] T082 [P] [US4] Create test for POST /api/albums/:id/photos - verify 400 error for non-existent file
- [x] T083 [P] [US4] Create test for POST /api/albums/:id/photos - verify 400 error for invalid image format
- [x] T084 [P] [US4] Create test for DELETE /api/photos/:id - verify photo removal (204 response)
- [x] T085 [P] [US4] Create test for GET /api/photos/:id/thumbnail - verify thumbnail generation and caching
- [x] T086 [US4] Create FileValidationServiceTests.swift - test file existence and format validation
- [x] T087 [US4] Create ThumbnailServiceTests.swift - test thumbnail generation with ImageIO
- [x] T088 [US4] Create integration test - verify adding photos updates album photoCount
- [x] T089 [US4] Run tests - verify ALL new tests FAIL (red phase)

### Implementation for User Story 4

- [x] T090 [P] [US4] Implement FileValidationService.validateImageFile(path:) to check file exists and format
- [x] T091 [P] [US4] Implement FileValidationService.getImageMetadata(path:) to extract width/height/format/size
- [x] T092 [P] [US4] Implement ThumbnailService.generateThumbnail(sourcePath:size:) using ImageIO
- [x] T093 [P] [US4] Implement ThumbnailService.getCachedThumbnail(photoId:) to check cache first
- [x] T094 [US4] Implement PhotoController.create in Sources/App/Controllers/PhotoController.swift (POST batch)
- [x] T095 [US4] Implement PhotoController.delete in Sources/App/Controllers/PhotoController.swift (DELETE)
- [x] T096 [US4] Implement PhotoController.thumbnail to serve thumbnails (GET /api/photos/:id/thumbnail)
- [x] T097 [US4] Add batch insert logic in PhotoController.create for multiple photos in single transaction
- [x] T098 [US4] Add auto-increment displayOrder logic when adding photos to album
- [x] T099 [US4] Register photo routes in routes.swift (POST, DELETE, thumbnail endpoint)
- [x] T100 [US4] Create file picker UI in Public/index.html (hidden input type="file" multiple)
- [x] T101 [US4] Implement addPhotosButton click handler in Public/js/photos.js
- [x] T102 [US4] Implement handlePhotoSelection() to get file paths and POST to API
- [x] T103 [US4] Implement renderPhotoTile(photo) to display thumbnail with data attributes
- [x] T104 [US4] Add photo delete button to each tile with confirmation
- [x] T105 [US4] Implement deletePhoto(photoId) function to call DELETE /api/photos/:id
- [x] T106 [US4] Add loading spinner for thumbnail generation (lazy load)
- [x] T107 [US4] Add error UI for missing files (placeholder image, "File not found" message)
- [x] T108 [US4] Add error UI for invalid formats (show supported formats list)
- [x] T109 [US4] Style photo tiles with hover effects and delete button positioning
- [x] T110 [US4] Optimize thumbnail loading with lazy loading and intersection observer
- [ ] T111 [US4] Run tests - verify ALL tests PASS (green phase)
- [ ] T112 [US4] Refactor thumbnail generation for better error handling
- [ ] T113 [US4] Manual testing: Add 50+ photos, verify performance <500ms per thumbnail

**Checkpoint**: User Story 4 complete - users can add and remove photos

---

## Phase 6: User Story 3 - Reorder Albums via Drag and Drop (Priority: P3)

**Goal**: Enable manual album reordering with drag-and-drop

**Independent Test**: Drag album to new position, verify order persists after refresh

### Tests for User Story 3 (TDD - Write These FIRST) ⚠️

- [x] T114 [P] [US3] Create test for PATCH /api/albums/reorder - verify batch customOrder update
- [x] T115 [P] [US3] Create test for PATCH /api/albums/reorder - verify transaction atomicity
- [x] T116 [P] [US3] Create test for GET /api/albums?sort=custom_order - verify custom ordering
- [x] T117 [US3] Create integration test - verify reorder persists across app restart
- [x] T118 [US3] Run tests - verify ALL new tests FAIL (red phase)

### Implementation for User Story 3

- [x] T119 [US3] Implement AlbumController.reorder in Sources/App/Controllers/AlbumController.swift (PATCH batch)
- [x] T120 [US3] Add transaction handling in reorder to ensure atomicity
- [x] T121 [US3] Update AlbumController.index to support ?sort=custom_order parameter
- [x] T122 [US3] Register reorder route in routes.swift (PATCH /api/albums/reorder)
- [x] T123 [US3] Implement HTML5 drag-and-drop in Public/js/albums.js (dragstart, dragover, drop events)
- [ ] T124 [US3] Add touch event polyfill for mobile support (touchstart, touchmove, touchend)
- [x] T125 [US3] Implement calculateNewOrder() function to compute customOrder values on drop
- [x] T126 [US3] Implement submitReorder(updates) function to PATCH /api/albums/reorder
- [x] T127 [US3] Add optimistic UI update during drag (visual reordering before API call)
- [x] T128 [US3] Add debouncing to avoid excessive API calls during rapid reordering (500ms delay)
- [x] T129 [US3] Implement rollback on API error (restore original order)
- [x] T130 [US3] Add "Reset to Date Order" button to clear custom ordering
- [x] T131 [US3] Implement resetToDateOrder() function to set customOrder=null for all albums
- [x] T132 [US3] Add CSS classes for drag states (dragging, drag-over, drop-target)
- [x] T133 [US3] Use CSS transforms for smooth drag animations (60 FPS target)
- [x] T134 [US3] Add visual feedback (ghost image, drop zone indicators)
- [x] T135 [US3] Ensure 44x44px minimum touch targets for mobile accessibility
- [ ] T136 [US3] Run tests - verify ALL tests PASS (green phase)
- [ ] T137 [US3] Refactor drag-drop code for better readability
- [ ] T138 [US3] Manual testing: Drag multiple albums, verify smooth 60 FPS animation

**Checkpoint**: User Story 3 complete - users can reorder albums

---

## Phase 7: User Story 5 - View Photos in Full Screen (Priority: P3)

**Goal**: Enable full-screen photo viewing with navigation

**Independent Test**: Click photo to open full-screen, navigate with arrows, close with Escape

### Tests for User Story 5 (TDD - Write These FIRST) ⚠️

- [ ] T139 [P] [US5] Create integration test - verify photo viewer loads correct image
- [ ] T140 [P] [US5] Create integration test - verify keyboard navigation (ArrowLeft, ArrowRight)
- [ ] T141 [US5] Create integration test - verify Escape key closes viewer
- [ ] T142 [US5] Run tests - verify ALL new tests FAIL (red phase)

### Implementation for User Story 5

- [x] T143 [US5] Create photo viewer modal structure in Public/index.html (full-screen overlay)
- [x] T144 [US5] Implement openPhotoViewer(photoIndex) function in Public/js/photos.js
- [x] T145 [US5] Implement renderFullscreenPhoto(photo) to display full-resolution image
- [x] T146 [US5] Implement navigatePhoto(direction) for next/prev photo navigation
- [x] T147 [US5] Add keyboard event listeners (ArrowLeft, ArrowRight, Escape)
- [ ] T148 [US5] Add touch swipe gesture support for mobile navigation (touchstart, touchmove, touchend)
- [x] T149 [US5] Implement closePhotoViewer() function to return to tile view
- [x] T150 [US5] Add photo index indicator (e.g., "3 / 15")
- [x] T151 [US5] Style full-screen viewer with CSS (centered image, dark overlay, controls)
- [x] T152 [US5] Add fade-in/fade-out transitions for smooth photo changes (<200ms)
- [x] T153 [US5] Optimize image loading (preload next/prev images)
- [x] T154 [US5] Add error handling for missing source files (show placeholder)
- [x] T155 [US5] Ensure accessibility (focus trap, ARIA labels, screen reader support)
- [ ] T156 [US5] Run tests - verify ALL tests PASS (green phase)
- [ ] T157 [US5] Refactor viewer code for better state management
- [ ] T158 [US5] Manual testing: Navigate through 20+ photos, verify <200ms transitions

**Checkpoint**: User Story 5 complete - users can view photos in full-screen

---

## Phase 8: User Preferences (Supporting Feature)

**Goal**: Enable users to customize app settings (theme, sort direction, thumbnail size)

**Purpose**: Supports multiple user stories with persistent preferences

### Tests for User Preferences (TDD - Write These FIRST) ⚠️

- [X] T159 [P] Create test for GET /api/preferences - verify default preferences on first launch
- [X] T160 [P] Create test for PATCH /api/preferences - verify preference updates
- [X] T161 [P] Create test for PATCH /api/preferences - verify validation (thumbnailSize 100-500)
- [X] T162 Run tests - verify ALL new tests FAIL (red phase)

### Implementation for User Preferences

- [X] T163 [P] Implement PreferenceController.show in Sources/App/Controllers/PreferenceController.swift (GET)
- [X] T164 [P] Implement PreferenceController.update in Sources/App/Controllers/PreferenceController.swift (PATCH)
- [X] T165 Add singleton initialization in configure.swift (create default preferences if missing)
- [X] T166 Add validation for sortDirection (ASC/DESC), thumbnailSize (100-500), theme (light/dark)
- [X] T167 Register preference routes in routes.swift
- [X] T168 Create settings modal UI in Public/index.html
- [X] T169 Implement loadPreferences() function in Public/js/utils.js
- [X] T170 Implement updatePreference(key, value) function to PATCH /api/preferences
- [X] T171 Add theme switcher (light/dark mode) with CSS variable updates
- [X] T172 Add sort direction toggle (newest/oldest first)
- [X] T173 Add thumbnail size slider (100-500px with live preview)
- [X] T174 Apply preferences on app load (theme, sort direction)
- [X] T175 Style settings modal with accessibility in mind
- [X] T176 Run tests - verify ALL tests PASS (green phase)
- [ ] T177 Refactor preference handling code
- [ ] T178 Manual testing: Change all preferences, verify persistence across refresh

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final polish, error handling, accessibility, and performance optimization

- [X] T179 [P] Add comprehensive error logging with Vapor's Logger throughout application
- [X] T180 [P] Add API error handling middleware for consistent error responses
- [ ] T181 [P] Implement database connection pooling optimization in configure.swift
- [ ] T182 [P] Add request rate limiting middleware (optional, for production)
- [X] T183 [P] Create comprehensive README.md with setup instructions and architecture overview
- [X] T184 [P] Add inline code documentation for public APIs and complex logic
- [ ] T185 Add ARIA labels and roles to all interactive elements
- [ ] T186 Test keyboard navigation through entire application (tab order, focus states)
- [ ] T187 Test screen reader compatibility (VoiceOver on macOS, NVDA on Windows)
- [ ] T188 Verify WCAG 2.1 Level AA compliance (contrast ratios, text sizes)
- [X] T189 Add focus visible styles for keyboard navigation
- [ ] T190 Test responsive design on various screen sizes (320px to 2560px wide)
- [ ] T191 Optimize CSS for mobile performance (minimize repaints, use transform/opacity)
- [ ] T192 Add service worker for offline thumbnail caching (optional enhancement)
- [ ] T193 Run performance profiling with Chrome DevTools (check 60 FPS during drag-drop)
- [ ] T194 Load test with 100+ albums and 10,000+ photos (verify <2s render time)
- [ ] T195 Measure API response times (verify <200ms for reads, <500ms for writes)
- [ ] T196 Run memory profiling to ensure no memory leaks in Swift backend
- [ ] T197 Verify SQLite query performance with EXPLAIN QUERY PLAN
- [ ] T198 Add database backup script (optional, for production)
- [ ] T199 Create user guide with screenshots (optional, for end users)
- [ ] T200 Final manual testing: Complete end-to-end user workflows for all 5 user stories

---

## Dependencies & Execution Strategy

### User Story Completion Order (by Priority)

```
Phase 1: Setup → Phase 2: Foundation
                        ↓
         ┌──────────────┼──────────────┐
         ↓              ↓              ↓
      US1 (P1)       US2 (P2)       US4 (P2)
   View Albums    Create Albums   Add Photos
         ↓              ↓              ↓
         └──────────────┼──────────────┘
                        ↓
                     US3 (P3)
                  Drag-Drop Reorder
                        ↓
                     US5 (P3)
                  Full-Screen View
                        ↓
                  Preferences
                        ↓
                     Polish
```

### Parallel Execution Opportunities

**Phase 1 (Setup)**: T003-T006, T010-T011 can run in parallel

**Phase 2 (Foundation)**:
- Models (T013-T015) → Migrations (T016-T018) → Services (T020-T021) [sequential]
- Frontend files (T023-T025) can run in parallel with backend models
- T010, T011, T027 can run in parallel

**Phase 3 (US1)**:
- Tests (T028-T029) can run in parallel
- Controllers (T036-T038) can run in parallel after tests written
- Frontend JS files (T042-T048) can run in parallel with controllers

**Phase 4 (US2)**:
- Tests (T056-T059) can run in parallel
- Controllers (T062-T064) can run in parallel
- Frontend work (T068-T075) can run in parallel

**Phase 5 (US4)**:
- Tests (T081-T087) can run in parallel
- Services (T090-T093) can run in parallel
- Controllers (T094-T099) depend on services

**Phase 6 (US3)**: Most tasks sequential due to drag-drop complexity

**Phase 7 (US5)**: Most frontend tasks can run in parallel (T143-T154)

**Phase 8 (Preferences)**: T159-T161 parallel, T163-T164 parallel

**Phase 9 (Polish)**: T179-T184 can all run in parallel

### MVP Scope (Minimum Viable Product)

**For initial release, implement ONLY**:
- Phase 1: Setup (all tasks)
- Phase 2: Foundation (all tasks)
- Phase 3: User Story 1 - View Albums (P1)
- Phase 4: User Story 2 - Create Albums (P2)
- Phase 5: User Story 4 - Add Photos (P2)

**This delivers**: Complete album management with photo browsing capability.

**Defer to v1.1**:
- Phase 6: User Story 3 - Drag-Drop (P3)
- Phase 7: User Story 5 - Full-Screen Viewer (P3)
- Phase 8: Preferences (enhancement)
- Phase 9: Polish (ongoing)

---

## Implementation Strategy

### TDD Workflow (MANDATORY)

For each user story phase:
1. **Red**: Write failing tests first (verify they fail)
2. **Green**: Implement minimal code to pass tests
3. **Refactor**: Clean up code while keeping tests green
4. **Repeat**: Move to next task

### Code Review Checkpoints

Before marking phase complete:
- [ ] All tests passing (`swift test`)
- [ ] Code coverage >80% (`xcodebuild test -enableCodeCoverage YES`)
- [ ] SwiftLint passes with no errors
- [ ] Manual testing confirms acceptance scenarios
- [ ] Performance targets met (from success criteria)

### Testing Requirements

- **Unit Tests**: Every model, service, controller method
- **Integration Tests**: Database operations, API endpoints
- **Contract Tests**: All API endpoints match OpenAPI spec
- **Manual Tests**: Complete user workflows
- **Performance Tests**: Render times, API latency, drag-drop FPS

---

## Task Summary

| Phase | Task Range | Count | Story | Can Parallelize |
|-------|------------|-------|-------|-----------------|
| Setup | T001-T012 | 12 | - | 6 tasks |
| Foundation | T013-T027 | 15 | - | 5 tasks |
| US1 (P1) | T028-T055 | 28 | View Albums | 8 tasks |
| US2 (P2) | T056-T080 | 25 | Create Albums | 7 tasks |
| US4 (P2) | T081-T113 | 33 | Add Photos | 10 tasks |
| US3 (P3) | T114-T138 | 25 | Drag-Drop | 4 tasks |
| US5 (P3) | T139-T158 | 20 | Full-Screen | 5 tasks |
| Preferences | T159-T178 | 20 | Support | 6 tasks |
| Polish | T179-T200 | 22 | Final | 12 tasks |
| **TOTAL** | **T001-T200** | **200** | **5 stories** | **63 parallel** |

**MVP Tasks**: T001-T113 (128 tasks, 65% of total)
**Enhancement Tasks**: T114-T200 (72 tasks, 35% of total)

---

**Ready to implement!** Start with Phase 1 (Setup), then Phase 2 (Foundation), then User Story 1 (P1 - MVP).

Follow TDD strictly: Write test → Verify it fails → Implement → Verify it passes → Refactor → Repeat.
