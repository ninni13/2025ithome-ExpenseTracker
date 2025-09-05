import Foundation
import FirebaseFirestore
import FirebaseAuth

class BudgetStore: ObservableObject {
    @Published var monthlyBudget: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: FirebaseFirestore.ListenerRegistration?
    
    func startListening(userId: String) {
        print("BudgetStore: Starting to listen for budget changes for user: \(userId)")
        
        stopListening()
        
        let budgetRef = db.collection("users").document(userId).collection("settings").document("budget")
        
        listenerRegistration = budgetRef.addSnapshotListener { [weak self] documentSnapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("BudgetStore: Error listening to budget: \(error)")
                    self?.errorMessage = "載入預算失敗: \(error.localizedDescription)"
                    return
                }
                
                guard let document = documentSnapshot else {
                    print("BudgetStore: Budget document does not exist")
                    self?.monthlyBudget = 0.0
                    return
                }
                
                if let data = document.data() {
                    self?.monthlyBudget = data["amount"] as? Double ?? 0.0
                    print("BudgetStore: Budget updated to: \(self?.monthlyBudget ?? 0.0)")
                } else {
                    print("BudgetStore: Budget document exists but has no data")
                    self?.monthlyBudget = 0.0
                }
            }
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func setBudget(_ amount: Double, userId: String, completion: @escaping (Bool, String?) -> Void) {
        guard amount >= 0 else {
            completion(false, "預算金額不能為負數")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let budgetRef = db.collection("users").document(userId).collection("settings").document("budget")
        
        budgetRef.setData([
            "amount": amount,
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("BudgetStore: Error setting budget: \(error)")
                    self?.errorMessage = "設定預算失敗: \(error.localizedDescription)"
                    completion(false, self?.errorMessage)
                } else {
                    print("BudgetStore: Budget set successfully to: \(amount)")
                    completion(true, nil)
                }
            }
        }
    }
    
    func getRemainingBudget(totalExpenses: Double) -> Double {
        return monthlyBudget - totalExpenses
    }
    
    func isOverBudget(totalExpenses: Double) -> Bool {
        return totalExpenses > monthlyBudget && monthlyBudget > 0
    }
}
