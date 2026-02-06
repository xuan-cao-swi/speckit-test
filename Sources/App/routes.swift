import Vapor

func routes(_ app: Application) throws {
    // Register controllers
    try app.register(collection: AlbumController())
    try app.register(collection: PhotoController())
    try app.register(collection: PreferenceController()) // T167: Register preference routes
    
    // T012: Register user authentication routes
    try app.register(collection: UserController())
    
    // T026: Register like routes
    try app.register(collection: LikeController())
}
