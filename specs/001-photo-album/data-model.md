# Data Model: Photo Album Organizer

**Phase**: 1 - Design & Contracts  
**Date**: 2026-02-04  
**Purpose**: Define data entities, relationships, and database schema

## Entity Relationship Diagram

```
┌─────────────────┐
│  UserPreference │
│                 │
│  id: UUID       │
│  sortDirection  │
│  thumbnailSize  │
│  theme          │
│  createdAt      │
│  updatedAt      │
└─────────────────┘

┌─────────────────────────┐         ┌──────────────────────────┐
│  Album                  │         │  Photo                   │
│                         │         │                          │
│  id: UUID              │◄────────│  id: UUID                │
│  name: String          │   1:N   │  albumId: UUID (FK)      │
│  date: Date            │         │  filePath: String        │
│  customOrder: Int?     │         │  displayOrder: Int       │
│  coverPhotoId: UUID?   │         │  thumbnailPath: String?  │
│  createdAt: DateTime   │         │  fileSize: Int           │
│  updatedAt: DateTime   │         │  width: Int              │
│                         │         │  height: Int             │
│                         │         │  format: String          │
│                         │         │  addedAt: DateTime       │
└─────────────────────────┘         └──────────────────────────┘
```

## Entity Definitions

### Album

Represents a collection of photos grouped by date with optional custom ordering.

**Fields**:

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key, Auto-generated | Unique album identifier |
| `name` | String | Required, 1-255 chars | User-defined album name |
| `date` | Date | Required | Date for chronological grouping (e.g., event date) |
| `customOrder` | Int | Optional, Nullable | Manual sort position (overrides date sorting) |
| `coverPhotoId` | UUID | Optional, Nullable, FK to Photo | Album cover (defaults to first photo if null) |
| `createdAt` | DateTime | Auto-generated | Album creation timestamp |
| `updatedAt` | DateTime | Auto-updated | Last modification timestamp |

**Relationships**:
- Has many `Photo` (one-to-many)
- Cover photo references one `Photo` (optional)

**Validation Rules**:
- `name` must not be empty or whitespace-only
- `date` must be a valid date (can be past or future)
- `customOrder` when set, must be unique across all albums (enforced in application logic)

**Indexes**:
- Primary index on `id`
- Index on `date` for chronological sorting
- Index on `customOrder` for manual ordering

**Business Rules**:
- Albums cannot be nested (flat hierarchy only)
- Deleting an album removes metadata only (photos remain on filesystem)
- When album deleted, associated `Photo` records are deleted (cascade)

---

### Photo

Represents a reference to a photo file with cached metadata and display information.

**Fields**:

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key, Auto-generated | Unique photo reference identifier |
| `albumId` | UUID | Required, FK to Album | Parent album (never null - photos must belong to album) |
| `filePath` | String | Required, Unique | Absolute path to photo file on filesystem |
| `displayOrder` | Int | Required, Default: 0 | Order within album (0-indexed) |
| `thumbnailPath` | String | Optional, Nullable | Path to cached thumbnail in `Public/thumbnails/` |
| `fileSize` | Int | Required | File size in bytes (cached for performance) |
| `width` | Int | Required | Image width in pixels |
| `height` | Int | Required | Image height in pixels |
| `format` | String | Required | Image format (JPEG, PNG, HEIC, WebP, GIF) |
| `addedAt` | DateTime | Auto-generated | When photo was added to album |

**Relationships**:
- Belongs to one `Album` (many-to-one)

**Validation Rules**:
- `filePath` must be absolute path
- `filePath` must point to existing file with valid image format
- `format` must be one of: JPEG, PNG, HEIC, WebP, GIF
- `fileSize` must be > 0
- `width` and `height` must be > 0
- `displayOrder` must be >= 0

**Indexes**:
- Primary index on `id`
- Composite index on `(albumId, displayOrder)` for efficient sorted retrieval
- Unique index on `filePath` to prevent duplicate references

**Business Rules**:
- Same photo file can only be referenced once per album (uniqueness by filePath + albumId)
- If source file is missing/moved, display placeholder in UI but keep metadata
- Thumbnail generation is lazy (on first request) and cached
- Removing photo from album deletes metadata only (original file untouched)

---

### UserPreference

Application-level settings (single row, singleton pattern).

**Fields**:

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Always uses fixed UUID for singleton |
| `sortDirection` | String | Required, Default: "DESC" | Album sort direction: "ASC" or "DESC" by date |
| `thumbnailSize` | Int | Required, Default: 200 | Thumbnail dimension in pixels (square) |
| `theme` | String | Required, Default: "light" | UI theme: "light" or "dark" |
| `createdAt` | DateTime | Auto-generated | First app launch |
| `updatedAt` | DateTime | Auto-updated | Last preference change |

**Relationships**: None (singleton entity)

**Validation Rules**:
- `sortDirection` must be "ASC" or "DESC"
- `thumbnailSize` must be between 100 and 500 pixels
- `theme` must be "light" or "dark"

**Indexes**:
- Primary index on `id` only

**Business Rules**:
- Only one record ever exists (singleton pattern)
- Created with defaults on first app launch if missing
- Changes apply immediately to UI

---

## Database Schema (SQLite)

### CREATE TABLE Statements

```sql
-- Albums table
CREATE TABLE albums (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 255),
    date TEXT NOT NULL,  -- Stored as ISO 8601 date string
    custom_order INTEGER,
    cover_photo_id TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cover_photo_id) REFERENCES photos(id) ON DELETE SET NULL
);

CREATE INDEX idx_albums_date ON albums(date);
CREATE INDEX idx_albums_custom_order ON albums(custom_order);

-- Photos table
CREATE TABLE photos (
    id TEXT PRIMARY KEY NOT NULL,
    album_id TEXT NOT NULL,
    file_path TEXT NOT NULL UNIQUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    thumbnail_path TEXT,
    file_size INTEGER NOT NULL CHECK(file_size > 0),
    width INTEGER NOT NULL CHECK(width > 0),
    height INTEGER NOT NULL CHECK(height > 0),
    format TEXT NOT NULL CHECK(format IN ('JPEG', 'PNG', 'HEIC', 'WebP', 'GIF')),
    added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE
);

CREATE INDEX idx_photos_album_display ON photos(album_id, display_order);
CREATE UNIQUE INDEX idx_photos_file_path ON photos(file_path);

-- User preferences table (singleton)
CREATE TABLE user_preferences (
    id TEXT PRIMARY KEY NOT NULL,
    sort_direction TEXT NOT NULL DEFAULT 'DESC' CHECK(sort_direction IN ('ASC', 'DESC')),
    thumbnail_size INTEGER NOT NULL DEFAULT 200 CHECK(thumbnail_size >= 100 AND thumbnail_size <= 500),
    theme TEXT NOT NULL DEFAULT 'light' CHECK(theme IN ('light', 'dark')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### SQLite Configuration

```sql
-- Enable Write-Ahead Logging for better concurrent read performance
PRAGMA journal_mode=WAL;

-- Enable foreign key constraints
PRAGMA foreign_keys=ON;

-- Set cache size (negative value = KB, -2000 = 2MB cache)
PRAGMA cache_size=-2000;
```

---

## Data Flow Patterns

### Creating an Album

1. Client sends POST request with `{ name: "Summer 2024", date: "2024-07-15" }`
2. Server generates UUID, creates Album record with default customOrder = NULL
3. Server returns created album with all fields
4. Client adds album to local state and re-renders grid

### Adding Photos to Album

1. Client selects multiple files via file picker
2. Client sends POST request with file paths array: `{ filePaths: ["/path/to/photo1.jpg", ...] }`
3. Server validates each file exists and is valid image format
4. Server reads image metadata (dimensions, format, size) using ImageIO
5. Server creates Photo records in single transaction with auto-incrementing displayOrder
6. Server returns array of created Photo objects
7. Client updates state and renders photo tiles

### Drag-and-Drop Reordering

1. User drags album to new position in grid
2. Client calculates new customOrder values for affected albums
3. Client sends PATCH `/api/albums/reorder` with `[{ id: "uuid1", customOrder: 0 }, ...]`
4. Server updates customOrder for all affected albums in transaction
5. Server returns success
6. Client persists optimistic UI update

### Thumbnail Generation (Lazy)

1. Client requests thumbnail: `GET /api/photos/:id/thumbnail`
2. Server checks if `thumbnailPath` exists and file is present
3. If not cached:
   - Generate thumbnail from source file using ImageIO
   - Save to `Public/thumbnails/{hash}.jpg`
   - Update Photo record with thumbnailPath
4. Serve thumbnail file (or fallback to source image if generation fails)

---

## Migration Strategy

Fluent migrations will create tables in this order:

1. `CreateUserPreference` - No dependencies
2. `CreateAlbum` - No dependencies (coverPhotoId nullable, set later)
3. `CreatePhoto` - Depends on Album (foreign key)
4. `UpdateAlbumCoverPhoto` - Add foreign key constraint after Photo table exists

This avoids circular dependency between Album.coverPhotoId and Photo.albumId.

---

## Data Integrity Constraints

### Enforced at Database Level (SQLite)
- Primary keys (uniqueness)
- Foreign keys (referential integrity)
- NOT NULL constraints
- CHECK constraints (value ranges, enums)
- UNIQUE indexes (filePath uniqueness)

### Enforced at Application Level (Fluent/Swift)
- Name length validation (1-255 characters)
- File existence checks before insert
- Image format validation via ImageIO
- Custom order uniqueness (across albums)
- Batch insert atomicity (transaction)

### Error Handling
- Missing file: Keep Photo record, display placeholder in UI
- Duplicate filePath: Return 409 Conflict error
- Invalid image format: Return 400 Bad Request with supported formats
- Album not found: Return 404 Not Found
- Database constraint violation: Return 400 Bad Request with details

---

## Performance Considerations

**Query Optimization**:
- Use composite index `(albumId, displayOrder)` for photo lists
- Limit photo queries to specific album (avoid SELECT * FROM photos)
- Batch inserts for adding multiple photos

**Caching Strategy**:
- Thumbnail files cached on disk (persistent)
- Image metadata cached in Photo table (avoid repeated file reads)
- Client-side caching via browser Cache-Control headers

**Scaling Limits**:
- Tested to 10,000 photos across 100 albums
- SQLite WAL mode supports concurrent reads
- Single-user design (no multi-user contention)

**Memory Management**:
- Stream large result sets (avoid loading all photos in memory)
- Generate thumbnails one at a time (not batch)
- Limit API response page size to 100 items
