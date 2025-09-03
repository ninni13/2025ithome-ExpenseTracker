import Foundation
import Firebase
import FirebaseFirestore

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    
    func addExpense(userId: String, expense: Expense) {
        db.collection("users").document(userId).collection("expenses").document(expense.id.uuidString).setData([
            "id": expense.id.uuidString,
            "amount": expense.amount,
            "category": expense.category,
            "date": expense.date
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
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let amount = data["amount"] as? Double,
                          let category = data["category"] as? String,
                          let date = data["date"] as? Timestamp else {
                        return nil
                    }
                    
                    return Expense(id: id, amount: amount, category: category, date: date.dateValue())
                }
                
                completion(expenses)
            }
    }
}
