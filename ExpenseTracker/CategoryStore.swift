import Foundation
import Firebase
import FirebaseFirestore

class CategoryStore: ObservableObject {
    @Published var categories: [Category] = []
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func startListening(userId: String) {
        listenerRegistration = db.collection("users").document(userId).collection("categories")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching categories: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let categories = documents.compactMap { Category(document: $0) }
                DispatchQueue.main.async {
                    self?.categories = categories.sorted { $0.createdAt < $1.createdAt }
                }
            }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func add(name: String, userId: String, completion: @escaping (Bool, String?) -> Void) {
        let category = Category(name: name)
        
        db.collection("users").document(userId).collection("categories").document(category.id).setData([
            "id": category.id,
            "name": category.name,
            "createdAt": Timestamp(date: category.createdAt)
        ]) { error in
            if let error = error {
                print("Error adding category: \(error)")
                completion(false, "新增類別失敗：\(error.localizedDescription)")
            } else {
                print("Successfully added category: \(name)")
                completion(true, nil)
            }
        }
    }
    
    func rename(id: String, newName: String, userId: String, completion: @escaping (Bool, String?) -> Void) {
        // 更新類別名稱
        db.collection("users").document(userId).collection("categories").document(id).updateData([
            "name": newName
        ]) { [weak self] error in
            if let error = error {
                print("Error renaming category: \(error)")
                completion(false, "重新命名失敗：\(error.localizedDescription)")
                return
            }
            
            // 批次更新所有使用此類別的支出
            self?.updateExpenseCategoryNames(categoryId: id, newName: newName, userId: userId)
            completion(true, nil)
        }
    }
    
    private func updateExpenseCategoryNames(categoryId: String, newName: String, userId: String) {
        let batch = db.batch()
        
        db.collection("users").document(userId).collection("expenses")
            .whereField("categoryId", isEqualTo: categoryId)
            .getDocuments { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching expenses for category update: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                for document in documents {
                    let expenseRef = self?.db.collection("users").document(userId).collection("expenses").document(document.documentID)
                    batch.updateData(["categoryName": newName], forDocument: expenseRef!)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error updating expense category names: \(error)")
                    } else {
                        print("Successfully updated \(documents.count) expenses with new category name")
                    }
                }
            }
    }
    
    func delete(id: String, userId: String, completion: @escaping (Bool, String?) -> Void) {
        // 檢查是否被使用
        isInUse(id: id, userId: userId) { [weak self] in
            if $0 {
                print("Cannot delete category: it is in use")
                completion(false, "此類別正在使用中，無法刪除")
                return
            }
            
            // 刪除類別
            self?.db.collection("users").document(userId).collection("categories").document(id).delete { error in
                if let error = error {
                    print("Error deleting category: \(error)")
                    completion(false, "刪除失敗：\(error.localizedDescription)")
                } else {
                    print("Successfully deleted category")
                    completion(true, nil)
                }
            }
        }
    }
    
    func isInUse(id: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).collection("expenses")
            .whereField("categoryId", isEqualTo: id)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error checking category usage: \(error)")
                    completion(false)
                    return
                }
                
                let count = querySnapshot?.documents.count ?? 0
                completion(count > 0)
            }
    }
    
    func getCategoryName(id: String) -> String? {
        return categories.first { $0.id == id }?.name
    }
}
