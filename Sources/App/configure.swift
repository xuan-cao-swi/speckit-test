import Vapor
import Fluent
import FluentSQLiteDriver

// Called before the application initializes
public func configure(_ app: Application) async throws {
    // Configure SQLite database with WAL mode for better concurrency
    app.databases.use(.sqlite(.file("db/photos.db")), as: .sqlite)
    
    // Enable WAL mode for better read performance
    if let db = app.db as? SQLDatabase {
        try await db.raw("PRAGMA journal_mode=WAL;").run()
    }
    
    // Register migrations
    app.migrations.add(CreateAlbum())
    app.migrations.add(CreatePhoto())
    app.migrations.add(CreateUserPreference())
    
    // Serve static files from Public directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Register routes
    try routes(app)
}
