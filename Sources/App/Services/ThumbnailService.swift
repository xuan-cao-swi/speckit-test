import Vapor
import Foundation

#if canImport(ImageIO)
import ImageIO
import CoreGraphics
#endif

struct ThumbnailService {
    let publicDirectory: String
    
    init(publicDirectory: String) {
        self.publicDirectory = publicDirectory
    }
    
    /// Generates a thumbnail from source image and saves to Public/thumbnails/
    func generateThumbnail(sourcePath: String, photoId: UUID, size: Int = 200) throws -> String {
        #if canImport(ImageIO)
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let thumbnailsDir = publicDirectory + "/thumbnails"
        let thumbnailPath = "\(thumbnailsDir)/\(photoId.uuidString).jpg"
        
        // Create thumbnails directory if it doesn't exist
        try FileManager.default.createDirectory(
            atPath: thumbnailsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Create image source
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw Abort(.internalServerError, reason: "Could not create image source")
        }
        
        // Create thumbnail options
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: size
        ]
        
        // Create thumbnail
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            throw Abort(.internalServerError, reason: "Could not create thumbnail")
        }
        
        // Save thumbnail as JPEG
        let destinationURL = URL(fileURLWithPath: thumbnailPath)
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            kUTTypeJPEG,
            1,
            nil
        ) else {
            throw Abort(.internalServerError, reason: "Could not create destination")
        }
        
        CGImageDestinationAddImage(destination, thumbnail, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            throw Abort(.internalServerError, reason: "Could not save thumbnail")
        }
        
        return thumbnailPath
        #else
        throw Abort(.notImplemented, reason: "ImageIO not available on this platform")
        #endif
    }
    
    /// Checks if thumbnail already exists in cache
    func getCachedThumbnail(photoId: UUID) -> String? {
        let thumbnailPath = "\(publicDirectory)/thumbnails/\(photoId.uuidString).jpg"
        
        if FileManager.default.fileExists(atPath: thumbnailPath) {
            return thumbnailPath
        }
        
        return nil
    }
    
    /// Gets image dimensions using ImageIO
    func getImageDimensions(path: String) -> (width: Int, height: Int)? {
        #if canImport(ImageIO)
        let imageURL = URL(fileURLWithPath: path)
        
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        
        return (width, height)
        #else
        return nil
        #endif
    }
}
