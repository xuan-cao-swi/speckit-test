# Quickstart Guide: Photo Album Organizer

**Phase**: 1 - Design & Contracts  
**Date**: 2026-02-04  
**Purpose**: Developer onboarding and local development setup

## Prerequisites

**Required**:
- Swift 5.9+ (check: `swift --version`)
- Xcode 15+ (macOS) or Swift toolchain (Linux)
- SQLite 3.x (usually pre-installed)

**Recommended**:
- macOS 13+ or Ubuntu 20.04+
- 8GB RAM minimum
- Modern browser (Chrome, Firefox, Safari)

## Quick Setup (5 minutes)

### 1. Create Project

```bash
# Create new Vapor project
vapor new PhotoAlbumOrganizer --no-fluent --no-leaf
cd PhotoAlbumOrganizer

# Or using Swift Package Manager directly
mkdir PhotoAlbumOrganizer && cd PhotoAlbumOrganizer
swift package init --type executable
```

### 2. Configure Package Dependencies

Edit `Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PhotoAlbumOrganizer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Vapor framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        // Fluent ORM
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // SQLite driver
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            path: "Tests/AppTests"
        )
    ]
)
```

### 3. Fetch Dependencies

```bash
swift package resolve
swift build
```

### 4. Create Directory Structure

```bash
# Create source directories
mkdir -p Sources/App/{Controllers,Models,Migrations,Services}
mkdir -p Public/{css,js,thumbnails}
mkdir -p Resources/Views
mkdir -p Tests/AppTests/{Controllers,Models,Integration}
mkdir -p db

# Create main entry point
touch Sources/App/main.swift
touch Sources/App/configure.swift
touch Sources/App/routes.swift
```

### 5. Basic Configuration Files

**Sources/App/main.swift**:
```swift
import Vapor

@main
struct Main {
    static func main() async throws {
        let app = Application()
        defer { app.shutdown() }
        
        try configure(app)
        try app.run()
    }
}
```

**Sources/App/configure.swift**:
```swift
import Vapor
import Fluent
import FluentSQLiteDriver

public func configure(_ app: Application) throws {
    // Database configuration
    app.databases.use(.sqlite(.file("db/photos.db")), as: .sqlite)
    
    // Middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    // Configure routes
    try routes(app)
    
    // Run migrations
    // app.migrations.add(CreateAlbum())
    // app.migrations.add(CreatePhoto())
    // app.migrations.add(CreateUserPreference())
    
    // SQLite configuration
    if let db = app.db as? SQLDatabase {
        try await db.raw("PRAGMA journal_mode=WAL").run()
        try await db.raw("PRAGMA foreign_keys=ON").run()
    }
}
```

**Sources/App/routes.swift**:
```swift
import Vapor

func routes(_ app: Application) throws {
    // Serve index.html at root
    app.get { req in
        return req.fileio.streamFile(at: app.directory.publicDirectory + "index.html")
    }
    
    // API routes will be added here
    let api = app.grouped("api")
    
    // Albums routes
    // api.get("albums", use: AlbumController.index)
    // api.post("albums", use: AlbumController.create)
    // ... more routes
}
```

### 6. Create Frontend Files

**Public/index.html**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Photo Album Organizer</title>
    <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
    <div id="app">
        <header>
            <h1>Photo Albums</h1>
            <button id="createAlbumBtn">+ New Album</button>
        </header>
        <main id="mainContent">
            <!-- Album grid will be rendered here -->
        </main>
    </div>
    
    <script type="module" src="/js/albums.js"></script>
</body>
</html>
```

**Public/css/styles.css**:
```css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #f5f5f5;
}

header {
    background: white;
    padding: 1rem 2rem;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

button {
    padding: 0.5rem 1rem;
    background: #007AFF;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1rem;
}

button:hover {
    background: #0051D5;
}

#mainContent {
    padding: 2rem;
}

/* Album grid styles will be added in implementation */
```

**Public/js/albums.js**:
```javascript
// Application state
const AppState = {
    albums: [],
    currentView: 'albums'
};

// Load albums on page load
async function loadAlbums() {
    try {
        const response = await fetch('/api/albums');
        const albums = await response.json();
        AppState.albums = albums;
        renderAlbums();
    } catch (error) {
        console.error('Failed to load albums:', error);
    }
}

function renderAlbums() {
    // Rendering logic will be implemented
    console.log('Albums:', AppState.albums);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadAlbums();
});
```

### 7. Run Development Server

```bash
# Build and run
swift run

# Server starts at http://localhost:8080
# Navigate to http://localhost:8080 in browser
```

## Development Workflow

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter AlbumTests

# Run with coverage (Xcode)
xcodebuild test -scheme PhotoAlbumOrganizer -enableCodeCoverage YES
```

### Database Management

```bash
# View SQLite database
sqlite3 db/photos.db

# Common queries
sqlite> .tables
sqlite> SELECT * FROM albums;
sqlite> .schema albums

# Reset database (careful!)
rm db/photos.db
swift run  # Migrations will recreate
```

### Code Quality

```bash
# Install SwiftLint (macOS)
brew install swiftlint

# Create .swiftlint.yml
cat > .swiftlint.yml << EOF
disabled_rules:
  - trailing_whitespace
line_length: 120
EOF

# Run linter
swiftlint
swiftlint --fix  # Auto-fix issues
```

### Hot Reload (Development)

For auto-restart on file changes:

```bash
# Install vapor-cli
brew install vapor

# Run with auto-reload
vapor run serve --auto-reload
```

## Project Structure Overview

```
PhotoAlbumOrganizer/
├── Package.swift              # Dependencies & build config
├── Sources/App/
│   ├── main.swift            # Application entry point
│   ├── configure.swift       # Vapor & database config
│   ├── routes.swift          # Route definitions
│   ├── Controllers/          # Request handlers
│   ├── Models/               # Fluent models (Album, Photo)
│   ├── Migrations/           # Database schema migrations
│   └── Services/             # Business logic (thumbnails, validation)
├── Public/                   # Static files (HTML, CSS, JS)
├── Resources/Views/          # Optional Leaf templates
├── Tests/AppTests/           # Unit & integration tests
└── db/                       # SQLite database file
```

## API Testing

### Using curl

```bash
# Create album
curl -X POST http://localhost:8080/api/albums \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Album","date":"2024-07-15"}'

# List albums
curl http://localhost:8080/api/albums

# Add photos to album
curl -X POST http://localhost:8080/api/albums/{albumId}/photos \
  -H "Content-Type: application/json" \
  -d '{"filePaths":["/path/to/photo.jpg"]}'
```

### Using Postman/Insomnia

Import OpenAPI spec from `specs/001-photo-album/contracts/api.yaml`

## Common Issues & Solutions

### Issue: "Swift not found"
**Solution**: Install Xcode or Swift toolchain
```bash
xcode-select --install  # macOS
# Or download from swift.org for Linux
```

### Issue: Database locked
**Solution**: SQLite WAL mode prevents most locks, but if encountered:
```bash
# Check for lingering processes
lsof db/photos.db
# Kill if needed, or restart server
```

### Issue: Port 8080 already in use
**Solution**: Change port in configure.swift:
```swift
app.http.server.configuration.port = 8081
```

### Issue: Thumbnail generation fails
**Solution**: Ensure ImageIO framework available (macOS only initially):
```swift
#if canImport(ImageIO)
import ImageIO
#else
#error("ImageIO not available on this platform")
#endif
```

## Next Steps

1. **Review Data Model**: See [data-model.md](data-model.md)
2. **Review API Contracts**: See [contracts/api.yaml](contracts/api.yaml)
3. **Create Models**: Implement Album, Photo, UserPreference in `Sources/App/Models/`
4. **Create Migrations**: Set up database schema in `Sources/App/Migrations/`
5. **Implement Controllers**: Add route handlers in `Sources/App/Controllers/`
6. **Write Tests**: TDD - write tests first, then implementation
7. **Build Frontend**: Complete HTML/CSS/JS in `Public/`

## Testing Checklist

Before starting implementation, ensure:

- [ ] Swift environment working (`swift --version`)
- [ ] Dependencies resolved (`swift package resolve`)
- [ ] Project builds (`swift build`)
- [ ] Server runs (`swift run`)
- [ ] Can access http://localhost:8080
- [ ] SQLite database created in `db/photos.db`
- [ ] Static files served from `Public/`

## Resources

- **Vapor Documentation**: https://docs.vapor.codes
- **Fluent Guide**: https://docs.vapor.codes/fluent/overview/
- **Swift.org**: https://swift.org/documentation/
- **SQLite Docs**: https://sqlite.org/docs.html
- **HTML5 Drag & Drop**: https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API

---

**Ready to implement?** Follow the TDD workflow:
1. Write failing test
2. Implement minimal code to pass
3. Refactor
4. Repeat

Start with User Story 1 (P1): View and Browse Photo Albums
