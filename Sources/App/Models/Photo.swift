import Fluent
import Vapor

final class Photo: Model, Content, @unchecked Sendable {
    static let schema = "photos"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "album_id")
    var album: Album
    
    // T009: Add owner relationship for likes feature (optional for backward compatibility)
    @OptionalParent(key: "owner_id")
    var owner: User?
    
    @Field(key: "file_path")
    var filePath: String
    
    @Field(key: "display_order")
    var displayOrder: Int
    
    @OptionalField(key: "thumbnail_path")
    var thumbnailPath: String?
    
    @Field(key: "file_size")
    var fileSize: Int
    
    @Field(key: "width")
    var width: Int
    
    @Field(key: "height")
    var height: Int
    
    @Field(key: "format")
    var format: String
    
    @Timestamp(key: "added_at", on: .create)
    var addedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        albumId: UUID,
        filePath: String,
        displayOrder: Int,
        thumbnailPath: String? = nil,
        fileSize: Int,
        width: Int,
        height: Int,
        format: String,
        ownerId: UUID? = nil
    ) {
        self.id = id
        self.$album.id = albumId
        self.filePath = filePath
        self.displayOrder = displayOrder
        self.thumbnailPath = thumbnailPath
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.format = format
        self.$owner.id = ownerId
    }
}

// MARK: - Validations
extension Photo: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("filePath", as: String.self, is: !.empty)
        validations.add("format", as: String.self, is: .in("JPEG", "PNG", "HEIC", "WebP", "GIF"))
        validations.add("fileSize", as: Int.self, is: .range(1...))
        validations.add("width", as: Int.self, is: .range(1...))
        validations.add("height", as: Int.self, is: .range(1...))
        validations.add("displayOrder", as: Int.self, is: .range(0...))
    }
}
