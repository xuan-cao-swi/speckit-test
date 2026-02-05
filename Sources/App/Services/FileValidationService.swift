import Vapor
import Foundation

struct FileValidationService {
    /// Validates that the file exists and is a supported image format
    func validateImageFile(path: String) throws {
        let fileURL = URL(fileURLWithPath: path)
        
        // Check file exists
        guard FileManager.default.fileExists(atPath: path) else {
            throw Abort(.badRequest, reason: "File not found: \(path)")
        }
        
        // Check file extension
        let supportedFormats = ["jpg", "jpeg", "png", "heic", "webp", "gif"]
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard supportedFormats.contains(fileExtension) else {
            throw Abort(.badRequest, reason: "Unsupported image format: \(fileExtension). Supported: \(supportedFormats.joined(separator: ", "))")
        }
    }
    
    /// Extracts image metadata (width, height, format, file size)
    func getImageMetadata(path: String) throws -> ImageMetadata {
        let fileURL = URL(fileURLWithPath: path)
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        guard let fileSize = attributes[.size] as? Int else {
            throw Abort(.internalServerError, reason: "Could not determine file size")
        }
        
        // For now, return basic metadata
        // ImageIO integration will be added in ThumbnailService
        let format = fileURL.pathExtension.uppercased()
        
        return ImageMetadata(
            width: 0,  // Will be populated by ImageIO in thumbnail service
            height: 0, // Will be populated by ImageIO in thumbnail service
            format: format,
            fileSize: fileSize
        )
    }
}

struct ImageMetadata {
    let width: Int
    let height: Int
    let format: String
    let fileSize: Int
}
