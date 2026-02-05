# Tasks: Social Media Likes for Photos and Albums

**Input**: Design documents from `/specs/002-photo-likes/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml, quickstart.md

**Tests**: Tests included as this is a TDD project per constitution requirements

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Configure SwiftLint for code quality standards per constitution
- [x] T002 [P] Review and update Package.swift dependencies (verify Vapor 4.x, Fluent, FluentSQLiteDriver)
- [x] T003 [P] Create test database configuration in Tests/AppTests/TestUtils.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### User Management Foundation

- [x] T004 Create User model in Sources/App/Models/User.swift with validation
- [x] T005 Create CreateUser migration in Sources/App/Migrations/CreateUser.swift
- [x] T006 [P] Create UpdateAlbumWithOwner migration in Sources/App/Migrations/UpdateAlbumWithOwner.swift
- [x] T007 [P] Create UpdatePhotoWithOwner migration in Sources/App/Migrations/UpdatePhotoWithOwner.swift
- [x] T008 Update Album model in Sources/App/Models/Album.swift to add ownerId relationship
- [x] T009 Update Photo model in Sources/App/Models/Photo.swift to add ownerId relationship

### Authentication Foundation

- [x] T010 Create UserSessionAuthenticator middleware in Sources/App/Middleware/UserSessionAuthenticator.swift
- [x] T011 Create UserController in Sources/App/Controllers/UserController.swift (login, logout, me endpoints)
- [x] T012 Add user routes to Sources/App/routes.swift (/api/users/login, /api/users/logout, /api/users/me)
- [x] T013 Configure session middleware in Sources/App/configure.swift

### Testing Foundation

- [x] T014 [P] Create UserTests in Tests/AppTests/Models/UserTests.swift
- [x] T015 [P] Create UserControllerTests in Tests/AppTests/Controllers/UserControllerTests.swift
- [x] T016 Run migrations and verify user authentication works: swift run App migrate

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 & 2 - Like and View Like Counts (Priority: P1) 🎯 MVP

**Goal**: Users can like/unlike photos and albums, and see like counts displayed on content

**Independent Test**: One user can like another user's photo/album, see the count increase, unlike it, and see the count decrease

### Tests for User Story 1 & 2 (Write FIRST, ensure they FAIL) ⚠️

- [x] T017 [P] [US1] Create LikeTests for Like model validation in Tests/AppTests/Models/LikeTests.swift
- [x] T018 [P] [US1] Create LikeServiceTests in Tests/AppTests/Services/LikeServiceTests.swift
  - Test likePhoto prevents self-like (throws error)
  - Test likePhoto is idempotent (same like returned)
  - Test unlikePhoto is idempotent (no error if not liked)
  - Test getPhotoLikeCount returns accurate count
  - Test hasUserLikedPhoto returns correct boolean
- [x] T019 [P] [US1] Create LikeControllerTests in Tests/AppTests/Controllers/LikeControllerTests.swift
  - Test POST /api/photos/:id/like returns 200 for valid like
  - Test POST /api/photos/:id/like returns 400 for self-like
  - Test POST /api/photos/:id/like returns 401 without authentication
  - Test DELETE /api/photos/:id/like returns 204
  - Test GET /api/photos/:id/likes returns correct count and user status

### Database Layer for User Story 1 & 2

- [x] T020 [US1] Create Like model in Sources/App/Models/Like.swift with XOR validation
- [x] T021 [US1] Create CreateLike migration in Sources/App/Migrations/CreateLike.swift
  - Add XOR check constraint (photoId XOR albumId)
  - Add unique indexes for (userId, photoId) and (userId, albumId)
  - Add indexes on photoId and albumId for counting
  - Add foreign key constraints with cascade delete
- [x] T022 [US1] Register Like migration in Sources/App/configure.swift and run: swift run App migrate

### Service Layer for User Story 1 & 2

- [x] T023 [US1] Create LikeService in Sources/App/Services/LikeService.swift
  - Implement likePhoto(photoId, userId, db) with self-like prevention
  - Implement unlikePhoto(photoId, userId, db) idempotent operation
  - Implement getPhotoLikeCount(photoId, db)
  - Implement hasUserLikedPhoto(photoId, userId, db)
  - Implement likeAlbum(albumId, userId, db) with self-like prevention
  - Implement unlikeAlbum(albumId, userId, db) idempotent operation
  - Implement getAlbumLikeCount(albumId, db)
  - Implement hasUserLikedAlbum(albumId, userId, db)

### API Layer for User Story 1 & 2

- [x] T024 [US1] Create LikeController in Sources/App/Controllers/LikeController.swift
  - Implement POST /api/photos/:photoId/like (likePhoto)
  - Implement DELETE /api/photos/:photoId/like (unlikePhoto)
  - Implement GET /api/photos/:photoId/likes (getPhotoLikes)
  - Implement POST /api/albums/:albumId/like (likeAlbum)
  - Implement DELETE /api/albums/:albumId/like (unlikeAlbum)
  - Implement GET /api/albums/:albumId/likes (getAlbumLikes)
- [x] T025 [US1] Create LikeResponse and LikeInfoResponse DTOs in Sources/App/Controllers/LikeController.swift
- [x] T026 [US1] Add like routes to Sources/App/routes.swift with UserSessionAuthenticator middleware
- [x] T027 [US1] Run tests to verify like API endpoints work: swift test --filter LikeControllerTests

### Frontend for User Story 1 & 2

- [x] T028 [P] [US2] Create like button component in Public/js/likes.js
  - Implement LikeButton class with render, toggle, fetchLikeInfo methods
  - Add optimistic UI updates (immediate visual feedback)
  - Add HTTP polling (2-second interval) for like count updates
  - Add error handling for self-like attempts
- [x] T029 [P] [US2] Add like button styles in Public/css/styles.css
  - Style .like-button with 44x44px minimum touch target
  - Add .liked state with visual differentiation
  - Add :hover and :disabled states
  - Style .like-count display
- [x] T030 [US2] Integrate like buttons into Public/js/photos.js (photo detail view)
- [x] T031 [US2] Integrate like buttons into Public/js/albums.js (album grid view)

### Extended API Responses for User Story 2

- [ ] T032 [US2] Update PhotoController in Sources/App/Controllers/PhotoController.swift
  - Extend GET /api/photos/:id response to include likeCount, isLikedByCurrentUser, isOwnedByCurrentUser
- [ ] T033 [US2] Update AlbumController in Sources/App/Controllers/AlbumController.swift
  - Extend GET /api/albums/:id response to include likeCount, isLikedByCurrentUser, isOwnedByCurrentUser

**Checkpoint**: At this point, User Stories 1 & 2 should be fully functional - users can like/unlike and see counts

---

## Phase 4: User Story 3 - Cannot Like Own Content (Priority: P2)

**Goal**: Prevent users from liking their own photos/albums, maintaining integrity of engagement metrics

**Independent Test**: A user viewing their own photo/album sees a disabled or hidden like button, and API rejects self-like attempts

### Tests for User Story 3 (Write FIRST) ⚠️

- [ ] T034 [P] [US3] Add self-like prevention test to Tests/AppTests/Services/LikeServiceTests.swift
  - Verify likePhoto throws Abort(.badRequest) when user is owner
  - Verify likeAlbum throws Abort(.badRequest) when user is owner
- [ ] T035 [P] [US3] Add self-like prevention test to Tests/AppTests/Controllers/LikeControllerTests.swift
  - Verify POST /api/photos/:id/like returns 400 with meaningful error message for owner

### Implementation for User Story 3

- [ ] T036 [US3] Update LikeService.likePhoto in Sources/App/Services/LikeService.swift
  - Add owner check: guard photo.$owner.id != userId else { throw Abort(.badRequest, reason: "Cannot like your own content") }
- [ ] T037 [US3] Update LikeService.likeAlbum in Sources/App/Services/LikeService.swift
  - Add owner check: guard album.$owner.id != userId else { throw Abort(.badRequest, reason: "Cannot like your own content") }
- [ ] T038 [US3] Update like button component in Public/js/likes.js
  - Hide or disable like button when isOwnedByCurrentUser is true
  - Add ARIA label: "You cannot like your own content"
- [ ] T039 [US3] Run tests to verify self-like prevention: swift test --filter LikeServiceTests

**Checkpoint**: Self-like prevention working at API and UI level

---

## Phase 5: User Story 4 - View Who Liked Content (Priority: P3)

**Goal**: Users can click on like count to see a list of usernames who liked the content

**Independent Test**: Click on a like count and verify a modal/list shows usernames of users who liked

### Tests for User Story 4 (Write FIRST) ⚠️

- [ ] T040 [P] [US4] Add liker list tests to Tests/AppTests/Controllers/LikeControllerTests.swift
  - Test GET /api/photos/:id/likers returns list of usernames
  - Test limit parameter restricts results
  - Test hasMore flag is correct when more likers exist

### Implementation for User Story 4

- [ ] T041 [P] [US4] Add getLikers method to LikeService in Sources/App/Services/LikeService.swift
  - Implement getPhotoLikers(photoId, limit, db) returning usernames and timestamps
  - Implement getAlbumLikers(albumId, limit, db) returning usernames and timestamps
- [ ] T042 [US4] Add liker endpoints to LikeController in Sources/App/Controllers/LikeController.swift
  - Implement GET /api/photos/:photoId/likers (getPhotoLikers)
  - Implement GET /api/albums/:albumId/likers (getAlbumLikers)
  - Create LikersResponse DTO with totalCount, likers array, hasMore flag
- [ ] T043 [US4] Add liker routes to Sources/App/routes.swift
- [ ] T044 [US4] Create liker list modal component in Public/js/likes.js
  - Implement showLikers() method in LikeButton class
  - Fetch /api/photos/:id/likers when like count clicked
  - Display modal with username list
  - Add "See more" button when hasMore is true
- [ ] T045 [US4] Add liker modal styles in Public/css/styles.css
- [ ] T046 [US4] Run tests to verify liker list functionality: swift test --filter LikeControllerTests

**Checkpoint**: All user stories (P1, P2, P3) are now fully implemented

---

## Phase 6: Integration Testing

**Purpose**: Verify all user stories work together and meet success criteria

- [ ] T047 [P] Create integration test in Tests/AppTests/Integration/LikeIntegrationTests.swift
  - Test complete flow: user login → view photo → like → see count → unlike
  - Test multi-user scenario: user1 likes, user2 sees updated count via polling
  - Test self-like prevention across all endpoints
  - Test cascade deletes (delete user → likes removed, delete photo → likes removed)
- [ ] T048 Run full integration test suite: swift test --filter IntegrationTests
- [ ] T049 Verify performance benchmarks from quickstart.md
  - Like creation <100ms p95
  - Like count query <50ms p95
  - API endpoint <200ms p95 total latency

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T050 [P] Add comprehensive error logging in LikeService for debugging
- [ ] T051 [P] Add rate limiting middleware (optional) to prevent like spam
- [ ] T052 Code review checklist:
  - All tests pass (swift test)
  - Code coverage ≥80% (swift test --enable-code-coverage)
  - SwiftLint passes with no warnings
  - All API endpoints documented in contracts/api.yaml match implementation
- [ ] T053 Update README.md with like feature documentation
- [ ] T054 Run quickstart.md validation to ensure guide is accurate
- [ ] T055 Performance optimization:
  - Add batch like count queries for displaying multiple photos/albums
  - Implement debouncing on frontend like button (prevent rapid clicks)
  - Add Intersection Observer to poll only for visible content

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories 1 & 2 (Phase 3)**: Depend on Foundational (Phase 2) - Core MVP functionality
- **User Story 3 (Phase 4)**: Can start after Phase 3 (needs Like model and service)
- **User Story 4 (Phase 5)**: Can start after Phase 3 (needs Like model and service)
- **Integration (Phase 6)**: Depends on all user stories being complete
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Stories 1 & 2 (P1)**: Combined because viewing counts is inseparable from liking - both are MVP critical
  - No dependencies on other user stories
  - Foundational phase MUST be complete (User model, authentication)
- **User Story 3 (P2)**: Extends User Stories 1 & 2 with self-like prevention
  - Depends on Like model and LikeService from Phase 3
  - Can be implemented independently after Phase 3
- **User Story 4 (P3)**: Adds "who liked" feature
  - Depends on Like model from Phase 3
  - Completely independent from User Story 3
  - Can be deferred if MVP scope needs to be reduced

### Within Each User Story

1. Tests MUST be written FIRST and FAIL before implementation
2. Database layer (models, migrations) before service layer
3. Service layer before API layer
4. API layer before frontend
5. Integration tests after all layers complete

### Parallel Opportunities

**Setup (Phase 1)**:
- All tasks can run in parallel (T001, T002, T003)

**Foundational (Phase 2)**:
- T004-T005: User model and migration (sequential)
- T006-T007: Album/Photo migrations can run in parallel AFTER T005
- T008-T009: Model updates can run in parallel AFTER migrations
- T010-T013: Authentication setup can run in parallel AFTER T009
- T014-T015: Tests can run in parallel

**User Story 1 & 2 (Phase 3)**:
- Tests (T017-T019) can all run in parallel
- Frontend tasks (T028-T029) can run in parallel with backend tasks
- T030-T031 (frontend integration) can run in parallel
- T032-T033 (controller updates) can run in parallel

**User Story 3 (Phase 4)**:
- T034-T035: Tests can run in parallel
- T036-T037: Service updates can run in parallel
- Can run in parallel with User Story 4 if team capacity allows

**User Story 4 (Phase 5)**:
- T041-T042: Backend implementation can run in parallel
- T044-T045: Frontend implementation can run in parallel with backend
- Can run in parallel with User Story 3 if team capacity allows

**Polish (Phase 7)**:
- T050-T051: Logging and rate limiting can run in parallel
- Most tasks in this phase can run in parallel

---

## Parallel Example: User Story 1 & 2 (Phase 3)

```bash
# Team member 1: Backend tests and implementation
swift test --filter LikeServiceTests  # T018 - write tests first
swift test --filter LikeControllerTests  # T019 - write tests first
# Implement T020-T027 (models, migrations, service, controller)

# Team member 2: Frontend (can start after T025 DTOs are defined)
# Implement T028-T029 (like button component and styles)
# Integrate T030-T031 (photos.js and albums.js)

# Team member 3: Extended API responses (after T023 service is done)
# Implement T032-T033 (update controllers with like info)

# All can work in parallel once foundational phase is complete
```

---

## MVP Scope Recommendation

**Minimum Viable Product** (deliver maximum value with minimal scope):

✅ **Include**:
- Phase 1: Setup
- Phase 2: Foundational (User authentication required)
- Phase 3: User Stories 1 & 2 (Like/unlike + view counts) - P1 priority
- Phase 4: User Story 3 (Prevent self-like) - P2 priority (important for integrity)
- Phase 6: Integration Testing (subset - core flows only)
- Phase 7: Polish (essential items only: T052 code review, T053 docs)

**Total MVP tasks**: ~45 tasks

⏸️ **Defer to v2**:
- Phase 5: User Story 4 (View who liked) - P3 priority, nice-to-have
- Phase 7: Polish (optional items: T051 rate limiting, T055 advanced optimizations)

**Rationale**: MVP delivers core social engagement (like/unlike with counts) and maintains integrity (prevent self-like). "Who liked" feature can be added after validating user interest in basic likes.

---

## Task Count Summary

- **Phase 1 (Setup)**: 3 tasks
- **Phase 2 (Foundational)**: 13 tasks
- **Phase 3 (User Stories 1 & 2 - P1)**: 16 tasks
- **Phase 4 (User Story 3 - P2)**: 4 tasks
- **Phase 5 (User Story 4 - P3)**: 6 tasks
- **Phase 6 (Integration)**: 3 tasks
- **Phase 7 (Polish)**: 6 tasks

**Total**: 51 tasks

**Parallel opportunities**: 25+ tasks marked [P] can run in parallel within their phase

**Independent test criteria**:
- US1 & US2: Can fully test like/unlike and view counts without other features
- US3: Can test self-like prevention independently
- US4: Can test liker list independently

**Format validation**: ✅ All tasks follow checklist format (checkbox, ID, labels, file paths)
