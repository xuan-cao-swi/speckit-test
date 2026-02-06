# Research: Social Media Likes for Photos and Albums

**Phase**: 0 - Outline & Research  
**Date**: 2026-02-05  
**Purpose**: Resolve NEEDS CLARIFICATION items and research best practices

## Research Tasks

From Technical Context, we identified the following unknowns:

1. **User Authentication Mechanism** - How to identify users for like tracking and ownership
2. **Real-time Update Strategy** - How to update like counts across client sessions

## Research Findings

### 1. User Authentication for Vapor (Swift)

**Research Question**: What is the simplest user authentication mechanism for a local, multi-user Vapor application with minimal dependencies?

**Decision**: **Simple Session-Based Authentication with Cookies**

**Rationale**:
- Aligns with "minimal dependencies" constraint from original spec
- Vapor includes built-in session support (no additional library needed)
- Appropriate for local deployment (not exposed to internet)
- Cookie-based sessions work seamlessly with browser-based UI
- No JWT library needed, no OAuth complexity
- Simple username-based identification (no password complexity for local use)

**Implementation Approach**:
```swift
// User Model: Simple identifier for tracking ownership
struct User: Model {
    var id: UUID?
    var username: String  // Unique, simple identifier
    var createdAt: Date
}

// Session stored in cookie, tracks current user
// Vapor's built-in SessionMiddleware handles cookie management
```

**Alternatives Considered**:
- **JWT tokens**: Rejected - overkill for local deployment, requires additional library (JWTKit)
- **OAuth/SSO**: Rejected - far too complex for local photo app
- **Basic HTTP Auth**: Rejected - poor UX (browser popup), no logout flow
- **No authentication (IP-based)**: Rejected - doesn't meet spec requirement for user identification

**Trade-offs**:
- ✅ Pros: Minimal code, no dependencies, simple UX, session persistence
- ⚠️ Cons: Not suitable for internet-facing deployment (but that's out of scope)

**Security Considerations** (for local deployment):
- Session cookies with HttpOnly flag (prevent XSS)
- CSRF protection for state-changing operations (like/unlike)
- Username uniqueness enforced at database level

---

### 2. Real-time Like Count Updates

**Research Question**: How should like counts update across multiple client sessions to meet <2s update requirement?

**Decision**: **HTTP Polling with Short Interval (2-3 seconds)**

**Rationale**:
- Simplest to implement with vanilla JavaScript (no WebSocket library)
- Meets <2s update requirement from success criteria
- Works within "minimal dependencies" constraint (no Socket.io, no server-side events library)
- Acceptable for expected scale (100 concurrent users)
- Gracefully degrades if network slow

**Implementation Approach**:
```javascript
// Client-side polling (vanilla JS)
setInterval(() => {
    fetch('/api/photos/' + photoId + '/like-count')
        .then(res => res.json())
        .then(data => updateLikeDisplay(data.count));
}, 2000); // Poll every 2 seconds
```

**Alternatives Considered**:
- **WebSockets**: Rejected - requires additional library (vapor-websocket or similar), adds complexity
- **Server-Sent Events (SSE)**: Rejected - Vapor doesn't have built-in SSE, would need custom implementation
- **Manual refresh only**: Rejected - doesn't meet real-time requirement from spec
- **Long polling**: Rejected - more complex than simple polling, minimal benefit at this scale

**Performance Analysis**:
- 100 users × 1 request/2s = 50 requests/second
- Vapor easily handles this load (<200ms response time target)
- Can optimize later with:
  - Poll only on visible photos/albums (Intersection Observer API)
  - Exponential backoff when page backgrounded
  - Batch requests (get counts for all visible items in one call)

**Trade-offs**:
- ✅ Pros: Simple implementation, no new dependencies, reliable
- ⚠️ Cons: Slightly higher server load than push-based (but well within capacity)
- ⚠️ Cons: Update latency 0-2s (acceptable per success criteria)

---

### 3. Preventing Race Conditions on Concurrent Likes

**Research Question**: How to prevent duplicate likes or incorrect counts when multiple users like simultaneously?

**Decision**: **Database Unique Constraint + Idempotent Operations**

**Rationale**:
- SQLite supports unique composite indexes
- Database-level enforcement prevents race conditions at source
- Idempotent API design (liking already-liked item is no-op)
- Aligns with Vapor's async/await for concurrent request handling

**Implementation Approach**:
```swift
// Migration: Unique constraint on (userId, photoId) and (userId, albumId)
.unique(on: "user_id", "photo_id")
.unique(on: "user_id", "album_id")

// Controller: Catch duplicate insert, return success (idempotent)
do {
    try await like.save(on: db)
    return .ok
} catch let error as DatabaseError where error.isConstraintFailure {
    return .ok  // Already liked, no-op
}
```

**Alternatives Considered**:
- **Application-level locking**: Rejected - complex, error-prone
- **SELECT before INSERT**: Rejected - still has race condition window
- **Optimistic locking with version field**: Rejected - overkill for this use case

**Trade-offs**:
- ✅ Pros: Guarantees correctness, simple logic, leverages database strength
- ✅ Pros: Idempotent API (retry-safe)
- ⚠️ Cons: Relies on exception handling for normal flow (debatable style)

---

### 4. Like Count Denormalization vs. COUNT Query

**Research Question**: Should like counts be stored as a field on Photo/Album, or calculated via COUNT query?

**Decision**: **Calculated via COUNT Query (No Denormalization)**

**Rationale**:
- Simpler implementation (no cache invalidation logic)
- Guaranteed accuracy (single source of truth)
- Acceptable performance with proper indexes
- Meets <200ms read latency requirement
- SQLite COUNT on indexed column is fast (<10ms for thousands of rows)

**Implementation Approach**:
```swift
// Query like count when needed
let likeCount = try await Like.query(on: db)
    .filter(\.$photo.$id == photoId)
    .count()
```

**Alternatives Considered**:
- **Denormalized count field**: Rejected - requires careful cache invalidation, potential for inconsistency
- **Materialized view**: Rejected - SQLite doesn't support materialized views
- **Counter table**: Rejected - adds complexity without significant benefit at this scale

**Performance Optimization**:
- Index on `like.photo_id` and `like.album_id`
- Batch count queries when displaying multiple items (single query with GROUP BY)
- Consider denormalization only if profiling shows COUNT is bottleneck (YAGNI principle)

**Trade-offs**:
- ✅ Pros: Simple, correct, maintainable
- ✅ Pros: No cache coherence issues
- ⚠️ Cons: Requires query per item (mitigated by batching and indexing)

---

### 5. Self-Like Prevention Strategy

**Research Question**: Where should "prevent self-like" logic be enforced?

**Decision**: **Layered Defense: API + Database Constraint**

**Rationale**:
- API layer provides fast feedback and clear error message
- Database constraint is safety net (defense in depth)
- Aligns with constitution's error handling principle

**Implementation Approach**:
```swift
// Service layer validation
func createLike(userId: UUID, photoId: UUID, db: Database) async throws {
    let photo = try await Photo.find(photoId, on: db)
    guard photo.ownerId != userId else {
        throw Abort(.badRequest, reason: "Cannot like your own content")
    }
    // ... proceed with like creation
}

// Database check constraint (if SQLite supports, otherwise app logic)
// This prevents bugs from bypassing service layer
```

**Alternatives Considered**:
- **API only**: Rejected - vulnerable to bugs or direct DB access
- **Database only**: Rejected - poor error messaging, requires complex check constraint
- **Client-side only**: Rejected - easily bypassed, not secure

**Trade-offs**:
- ✅ Pros: Defense in depth, clear error messages
- ✅ Pros: Meets constitution's "explicit error handling" requirement
- ⚠️ Cons: Slight code duplication (acceptable for correctness)

---

## Technology Stack Summary

Based on research decisions, the technology stack is:

**Backend**:
- Swift 5.9+ with Vapor 4.x (existing)
- Fluent ORM with SQLite driver (existing)
- Built-in SessionMiddleware for authentication (no additional dependency)
- XCTest for testing (existing)

**Frontend**:
- Vanilla JavaScript (existing, no framework)
- Fetch API for HTTP polling
- DOM manipulation for like button state

**Database**:
- SQLite with composite unique indexes
- No additional tools required

**No New External Dependencies** - All solutions use built-in Vapor and Swift features, meeting the "minimal dependencies" constraint.

---

## Best Practices Applied

### Swift Vapor Best Practices

1. **Async/await**: Use Vapor's async/await for database operations (prevents blocking)
2. **Route protection**: Use middleware to ensure user session exists before like operations
3. **DTO pattern**: Separate API response models from database models (e.g., `PhotoResponse` includes `likeCount`)
4. **Validation**: Use Vapor's Validatable protocol for input validation
5. **Error handling**: Return appropriate HTTP status codes (400 for self-like, 401 for unauthenticated)

### Database Best Practices

1. **Indexes**: Create indexes on foreign keys (`user_id`, `photo_id`, `album_id`)
2. **Constraints**: Use unique constraints for data integrity
3. **Cascade deletes**: When photo/album deleted, cascade delete associated likes
4. **Migrations**: Use Fluent migrations for schema changes (reversible)

### Frontend Best Practices

1. **Optimistic UI**: Update like button state immediately, rollback on error
2. **Debouncing**: Prevent rapid clicking with disabled state during API call
3. **Accessibility**: ARIA labels for like button state ("Liked", "Not liked")
4. **Error handling**: Display user-friendly error messages

### Security Best Practices (Local Deployment)

1. **Session cookies**: HttpOnly, SameSite=Lax to prevent XSS/CSRF
2. **Input validation**: Validate UUIDs before database queries
3. **SQL injection prevention**: Use Fluent's query builder (parameterized queries)
4. **Rate limiting**: Consider adding rate limit middleware if abuse detected (optional)

---

## Open Questions / Future Considerations

**For Current Implementation**:
- None - all NEEDS CLARIFICATION items resolved

**For Future Iterations** (out of current scope):
- Notifications when content is liked (referenced in spec's "Out of Scope")
- Who liked this content UI (User Story 4, Priority P3 - may defer)
- Like activity feed or trending content (out of scope)
- Export like data (out of scope)

---

## Conclusion

All technical uncertainties have been resolved with decisions that:
- ✅ Meet constitutional requirements (minimal dependencies, testability, performance)
- ✅ Align with existing architecture (Vapor, SQLite, vanilla JS)
- ✅ Satisfy success criteria (<1s feedback, <2s updates, 100% self-like prevention)
- ✅ Follow best practices for Swift Vapor development

**Ready to proceed to Phase 1: Data Model Design**
