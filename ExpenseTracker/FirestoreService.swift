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
            "categoryId": expense.categoryId,
            "categoryName": expense.categoryName
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
                    
                    // 檢查分類欄位（可選）
                    let categoryId = data["categoryId"] as? String ?? "default"
                    let categoryName = data["categoryName"] as? String ?? "未分類"
                    
                    print("Firestore: Creating expense with categoryId: \(categoryId), categoryName: \(categoryName)")
                    
                    return Expense(id: id, amount: amount, date: date.dateValue(), categoryId: categoryId, categoryName: categoryName)
                }
                
                completion(expenses)
            }
    }
}
