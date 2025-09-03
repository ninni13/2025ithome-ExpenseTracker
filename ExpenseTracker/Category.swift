import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
    
    // 從 Firestore 文件轉換
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.createdAt = createdAt.dateValue()
    }
}
