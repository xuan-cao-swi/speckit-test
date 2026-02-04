# Photo Album Organizer

> A modern, desktop-based photo album organizer built with Swift Vapor backend and vanilla JavaScript frontend.

## Features

✅ **Album Management**
- Create, edit, and delete photo albums
- Sort albums by date (newest/oldest first)
- Drag-and-drop reordering with custom order
- Modal-based UI with keyboard shortcuts

✅ **Photo Management**
- Batch photo upload with file validation
- Automatic thumbnail generation (ImageIO)
- Lazy loading and caching
- Photo deletion with cascade support

✅ **Full-Screen Viewer**
- Keyboard navigation (Arrow keys, Escape)
- Image preloading for smooth transitions
- Photo index indicator
- Accessible with ARIA labels

✅ **User Preferences**
- Light/Dark theme toggle
- Customizable thumbnail size (100-500px)
- Sort direction persistence
- Settings sync via REST API

✅ **Responsive & Accessible**
- Mobile-first responsive design
- WCAG 2.1 Level AA compliant
- Keyboard-only navigation support
- Screen reader compatible

## Tech Stack

**Backend**
- Swift 5.9+
- Vapor 4.x web framework
- Fluent ORM with SQLite
- ImageIO for thumbnail generation

**Frontend**
- Vanilla HTML5/CSS3/JavaScript
- No build tools required
- Native drag-and-drop API
- CSS Grid & Flexbox layout

**Testing**
- XCTest with XCTVapor
- TDD workflow (Red-Green-Refactor)
- Unit, integration, and contract tests

## Prerequisites

- macOS 12.0+ (for ImageIO framework)
- Swift 5.9 or later
- Xcode 15.0+ (optional, for development)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd speckit-test
```

### 2. Build the Project

```bash
swift build
```

### 3. Run Database Migrations

```bash
swift run PhotoAlbumOrganizer migrate --yes
```

### 4. Start the Server

```bash
swift run PhotoAlbumOrganizer serve
```

The application will be available at `http://localhost:8080`

## Development

### Project Structure

```
.
├── Sources/App/
│   ├── Controllers/         # API endpoint handlers
│   │   ├── AlbumController.swift
│   │   ├── PhotoController.swift
│   │   └── PreferenceController.swift
│   ├── Models/             # Database models
│   │   ├── Album.swift
│   │   ├── Photo.swift
│   │   └── UserPreference.swift
│   ├── Migrations/         # Database schema
│   │   ├── CreateAlbum.swift
│   │   ├── CreatePhoto.swift
│   │   └── CreateUserPreference.swift
│   ├── Services/           # Business logic
│   │   ├── FileValidationService.swift
│   │   └── ThumbnailService.swift
│   ├── configure.swift     # App configuration
│   ├── routes.swift        # Route registration
│   └── main.swift          # Entry point
├── Public/                 # Static assets
│   ├── css/
│   │   └── styles.css
│   ├── js/
│   │   ├── albums.js
│   │   ├── photos.js
│   │   └── utils.js
│   └── index.html
├── Tests/AppTests/         # Test suite
│   ├── Controllers/
│   ├── Models/
│   ├── Services/
│   └── Integration/
└── db/                     # SQLite database
    └── photos.db
```

### API Endpoints

**Albums**
- `GET /api/albums` - List all albums
  - Query params: `?sort=custom_order` for custom ordering
- `GET /api/albums/:id` - Get album details
- `POST /api/albums` - Create album
- `PATCH /api/albums/:id` - Update album
- `DELETE /api/albums/:id` - Delete album (cascade to photos)
- `PATCH /api/albums/reorder` - Batch reorder albums

**Photos**
- `GET /api/albums/:id/photos` - List photos in album
- `POST /api/albums/:id/photos` - Batch add photos
- `DELETE /api/photos/:id` - Delete photo
- `GET /api/photos/:id/thumbnail` - Get thumbnail image

**Preferences**
- `GET /api/preferences` - Get user preferences
- `PATCH /api/preferences` - Update preferences

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter AlbumControllerTests

# Run with code coverage
swift test --enable-code-coverage
```

### Database Schema

**Albums Table**
- `id` (UUID, PK)
- `name` (String, 1-255 chars)
- `date` (Date, ISO8601 format)
- `custom_order` (Int, nullable)
- `cover_photo_id` (UUID, nullable, FK to Photos)

**Photos Table**
- `id` (UUID, PK)
- `album_id` (UUID, FK to Albums, ON DELETE CASCADE)
- `file_path` (String)
- `display_order` (Int, auto-increment per album)
- `file_size` (Int64, bytes)
- `width` (Int, pixels)
- `height` (Int, pixels)
- `format` (String, e.g., "JPEG")

**User Preferences Table**
- `id` (UUID, PK, singleton)
- `sort_direction` (String, "ASC" or "DESC")
- `thumbnail_size` (Int, 100-500)
- `theme` (String, "light" or "dark")

## Configuration

### Environment Variables

- `LOG_LEVEL` - Logging level (debug, info, warning, error)
- `DATABASE_PATH` - Custom SQLite database path (default: db/photos.db)

### Performance Targets

- Album render time: <2 seconds (per Success Criteria)
- Thumbnail generation: <500ms per photo
- Drag-drop animation: 60 FPS (16ms frame delay)
- Photo viewer transitions: <200ms
- API response time: <200ms (reads), <500ms (writes)

## Keyboard Shortcuts

- `Escape` - Close modal/viewer
- `Enter` - Submit form (in modals)
- `Arrow Left/Right` - Navigate photos (in full-screen viewer)
- `Tab` - Navigate through interactive elements

## Browser Support

- Modern browsers with ES6+ support
- Chrome 90+
- Safari 14+
- Firefox 88+
- Edge 90+

## Accessibility

- WCAG 2.1 Level AA compliant
- Keyboard-only navigation
- Screen reader support (ARIA labels)
- High contrast mode compatible
- Minimum 44x44px touch targets

## License

This project is created for educational purposes.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Database Locked Error

If you encounter "database is locked" errors:

```bash
# Reset WAL mode
rm db/photos.db-wal db/photos.db-shm
swift run PhotoAlbumOrganizer migrate --revert --yes
swift run PhotoAlbumOrganizer migrate --yes
```

### Port Already in Use

```bash
# Find and kill process using port 8080
lsof -ti:8080 | xargs kill -9

# Or use a different port
swift run PhotoAlbumOrganizer serve --port 8081
```

### Missing Thumbnails

Thumbnails are generated on-demand. If missing:

1. Check file paths are absolute
2. Ensure ImageIO framework is available (macOS only)
3. Verify image formats are supported (JPEG, PNG, HEIC, WebP, GIF)

## Performance Tips

- Enable WAL mode for SQLite (already configured)
- Use SSD for database storage
- Keep thumbnail cache in Public/thumbnails/
- Enable HTTP/2 for production deployments
- Use CDN for static assets in production

## Roadmap

- [ ] Multi-user support with authentication
- [ ] Cloud storage integration (S3, Azure Blob)
- [ ] Advanced search and filtering
- [ ] Bulk operations (move, copy photos between albums)
- [ ] Export albums (ZIP, PDF)
- [ ] Photo editing (crop, rotate, filters)
- [ ] Mobile app (iOS/Android)

## Support

For issues and questions, please open a GitHub issue.

---

**Built with ❤️ using Swift Vapor and modern web technologies**
