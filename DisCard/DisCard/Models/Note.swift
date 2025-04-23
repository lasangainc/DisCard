import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var expiryDate: Date
    
    init(id: UUID = UUID(), title: String, content: String, expiryDate: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.expiryDate = expiryDate
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.content == rhs.content &&
               lhs.expiryDate == rhs.expiryDate
    }
} 