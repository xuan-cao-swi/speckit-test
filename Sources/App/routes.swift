import Vapor

func routes(_ app: Application) throws {
    // Register controllers
    try app.register(collection: AlbumController())
    try app.register(collection: PhotoController())
}
