import Vapor
import Fluent
import FluentSQLiteDriver
import SQLKit

// Called before the application initializes
public func configure(_ app: Application) async throws {
    // Configure logging level based on environment
    app.logger.logLevel = app.environment == .production ? .info : .debug
    
    // Configure SQLite database
    // Use in-memory database for testing, file-based for production/development
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db/photos.db")), as: .sqlite)
        
        // Enable WAL mode for better read performance (file-based only)
        if let db = app.db as? (any SQLDatabase) {
            try await db.raw("PRAGMA journal_mode=WAL;").run()
        }
    }
    
    // T013: Configure session middleware for user authentication
    app.sessions.use(.fluent)
    app.middleware.use(app.sessions.middleware)
    
    // Register migrations
    app.migrations.add(CreateAlbum())
    app.migrations.add(CreatePhoto())
    app.migrations.add(CreateUserPreference())
    
    // T005, T006, T007: User and ownership migrations
    app.migrations.add(CreateUser())
    app.migrations.add(UpdateAlbumWithOwner())
    app.migrations.add(UpdatePhotoWithOwner())
    
    // T013: Session storage migration
    app.migrations.add(SessionRecord.migration)
    
    // T021, T022: Like model migration
    app.migrations.add(CreateLike())
    
    // T020: Like model middleware for XOR validation
    app.databases.middleware.use(LikeXORMiddleware())
    
    // Configure middleware
    // Error handling middleware - catches and formats errors
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    // Serve static files from Public directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Register routes
    try routes(app)
}
