import Foundation
import Firebase
import FirebaseFirestore

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    
    func addExpense(userId: String, expense: Expense) {
        db.collection("users").document(userId).collection("expenses").document(expense.id.uuidString).setData([
            "id": expense.id.uuidString,
            "amount": expense.amount,
            "date": expense.date,
            "category": expense.category
        ]) { error in
            if let error = error {
                print("Error adding expense: \(error)")
            }
        }
    }
    
    func deleteExpense(userId: String, expenseId: String) {
        db.collection("users").document(userId).collection("expenses").document(expenseId).delete() { error in
            if let error = error {
                print("Error removing expense: \(error)")
            }
        }
    }
    
    func listenToExpenses(userId: String, completion: @escaping ([Expense]) -> Void) -> FirebaseFirestore.ListenerRegistration {
        return db.collection("users").document(userId).collection("expenses")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let expenses = documents.compactMap { document -> Expense? in
                    let data = document.data()
                    print("Firestore: Document data: \(data)")
                    
                    // 檢查是否有必要的欄位
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let amount = data["amount"] as? Double,
                          let date = data["date"] as? Timestamp else {
                        print("Firestore: Missing required fields in document")
                        return nil
                    }
                    
                    // 檢查分類欄位（支援舊格式和新格式）
                    var category = "未分類"  // 改為「未分類」
                    if let newCategory = data["category"] as? String {
                        category = newCategory
                    } else if let oldCategoryName = data["categoryName"] as? String {
                        category = oldCategoryName
                    }
                    
                    print("Firestore: Creating expense with category: \(category), amount: \(amount)")
                    
                    return Expense(id: id, amount: amount, category: category, date: date.dateValue())
                }
                
                completion(expenses)
            }
    }
}
