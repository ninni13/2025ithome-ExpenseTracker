import SwiftUI

struct BudgetSettingsView: View {
    @EnvironmentObject var budgetStore: BudgetStore
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var budgetAmount: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("每月預算設定")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("設定您的每月支出預算，幫助控制開支")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Current Budget Display
                VStack(spacing: 12) {
                    Text("目前預算")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(budgetStore.monthlyBudget))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(budgetStore.monthlyBudget > 0 ? .primary : .secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Budget Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("新預算金額")
                        .font(.headline)
                    
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        TextField("輸入預算金額", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveBudget) {
                        HStack {
                            if budgetStore.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("儲存預算")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(budgetStore.isLoading || budgetAmount.isEmpty)
                    
                    Button(action: clearBudget) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("清除預算")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.secondary)
                        .cornerRadius(12)
                    }
                    .disabled(budgetStore.isLoading)
                }
                
                Spacer()
                
                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 小提示")
                        .font(.headline)
                        .foregroundColor(.pink)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 預算為 0 時表示未設定預算")
                        Text("• 當支出超過預算時會顯示警告")
                        Text("• 預算設定會即時同步到主頁面")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("預算管理")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                budgetAmount = budgetStore.monthlyBudget > 0 ? String(format: "%.0f", budgetStore.monthlyBudget) : ""
            }
            .alert("預算設定", isPresented: $showingAlert) {
                Button("確定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveBudget() {
        guard let amount = Double(budgetAmount), amount >= 0 else {
            alertMessage = "請輸入有效的預算金額"
            showingAlert = true
            return
        }
        
        guard let userId = authManager.currentUser?.uid else {
            alertMessage = "請先登入"
            showingAlert = true
            return
        }
        
        budgetStore.setBudget(amount, userId: userId) { success, errorMessage in
            if success {
                alertMessage = "預算設定成功！"
                showingAlert = true
                presentationMode.wrappedValue.dismiss()
            } else {
                alertMessage = errorMessage ?? "設定失敗"
                showingAlert = true
            }
        }
    }
    
    private func clearBudget() {
        guard let userId = authManager.currentUser?.uid else {
            alertMessage = "請先登入"
            showingAlert = true
            return
        }
        
        budgetStore.setBudget(0, userId: userId) { success, errorMessage in
            if success {
                budgetAmount = ""
                alertMessage = "預算已清除"
                showingAlert = true
            } else {
                alertMessage = errorMessage ?? "清除失敗"
                showingAlert = true
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct BudgetSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetSettingsView()
            .environmentObject(BudgetStore())
            .environmentObject(AuthManager())
    }
}
