import Fluent
import Vapor

final class Album: Model, Content, @unchecked Sendable {
    static let schema = "albums"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "date")
    var date: Date
    
    @OptionalField(key: "custom_order")
    var customOrder: Int?
    
    @OptionalField(key: "cover_photo_id")
    var coverPhotoId: UUID?
    
    // T008: Add owner relationship for likes feature (optional for backward compatibility)
    @OptionalParent(key: "owner_id")
    var owner: User?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$album)
    var photos: [Photo]
    
    init() { }
    
    init(id: UUID? = nil, name: String, date: Date, customOrder: Int? = nil, coverPhotoId: UUID? = nil, ownerId: UUID? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.customOrder = customOrder
        self.coverPhotoId = coverPhotoId
        self.$owner.id = ownerId
    }
}

// MARK: - Validations
extension Album: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(1...255))
    }
}

// MARK: - Computed Properties
extension Album {
    var photoCount: Int {
        get async throws {
            return photos.count
        }
    }
}
