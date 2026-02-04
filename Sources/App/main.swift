import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = try await Application.make(env)

// Register shutdown hook
defer { app.shutdown() }

// Configure the application
try await configure(app)
try await app.execute()

