//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/8/27.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Expense Model
struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let category: String
    let date: Date
    
    init(id: UUID = UUID(), amount: Double, category: String = "一般", date: Date) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
    }
}

// MARK: - ExpenseStore
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    private let firestoreService = FirestoreService()
    private var listenerRegistration: FirebaseFirestore.ListenerRegistration?
    
    func startListening(userId: String) {
        listenerRegistration = firestoreService.listenToExpenses(userId: userId) { [weak self] expenses in
            DispatchQueue.main.async {
                self?.expenses = expenses
            }
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func add(amount: Double, category: String, date: Date, userId: String) {
        let expense = Expense(amount: amount, category: category, date: date)
        firestoreService.addExpense(userId: userId, expense: expense)
    }
    
    func delete(expense: Expense, userId: String) {
        firestoreService.deleteExpense(userId: userId, expenseId: expense.id.uuidString)
    }
    
    var monthlyTotal: Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        return expenses
            .filter { calendar.isDate($0.date, equalTo: currentDate, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 計算本月各分類的統計
    var monthlyCategorySummaries: [CategorySummary] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // 過濾本月的支出
        let monthlyExpenses = expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: currentDate, toGranularity: .month)
        }
        
        print("ExpenseStore: Found \(monthlyExpenses.count) expenses for current month")
        for expense in monthlyExpenses {
            print("ExpenseStore: \(expense.category) - $\(expense.amount) - \(expense.date)")
        }
        
        // 按類別分組並計算總額
        var categoryTotals: [String: Double] = [:]
        
        for expense in monthlyExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        print("ExpenseStore: Category totals: \(categoryTotals)")
        
        // 轉換為 CategorySummary 陣列
        return categoryTotals.map { categoryName, total in
            CategorySummary(categoryName: categoryName, total: total)
        }.sorted { $0.total > $1.total }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var categoryStore: CategoryStore
    @State private var amountText = ""
    @State private var selectedDate = Date()
    @State private var selectedCategoryId = ""
    @State private var showingCategoryManagement = false
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    private var amount: Double {
        Double(amountText) ?? 0
    }
    
    private var isAddButtonDisabled: Bool {
        amount <= 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Input Section
                VStack(spacing: 16) {
                    HStack {
                        Text("金額:")
                            .frame(width: 60, alignment: .leading)
                        TextField("請輸入金額", text: $amountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("分類:")
                            .frame(width: 60, alignment: .leading)
                        if categoryStore.categories.isEmpty {
                            Button("新增類別") {
                                showingCategoryManagement = true
                            }
                            .foregroundColor(.blue)
                        } else {
                            Picker("分類", selection: $selectedCategoryId) {
                                Text("請選擇類別").tag("")
                                ForEach(categoryStore.categories) { category in
                                    Text(category.name).tag(category.id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    HStack {
                        Text("日期:")
                            .frame(width: 60, alignment: .leading)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    Button("新增紀錄") {
                        if let userId = authManager.currentUser?.uid {
                            if let category = categoryStore.categories.first(where: { $0.id == selectedCategoryId }) {
                                print("ContentView: Adding expense - Amount: \(amount), Category: \(category.name), Date: \(selectedDate)")
                                expenseStore.add(amount: amount, category: category.name, date: selectedDate, userId: userId)
                                amountText = ""
                                selectedCategoryId = ""
                            }
                        }
                    }
                    .disabled(isAddButtonDisabled || selectedCategoryId.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Monthly Total
                HStack {
                    Text("本月總支出:")
                        .font(.headline)
                    Spacer()
                    Text(numberFormatter.string(from: NSNumber(value: expenseStore.monthlyTotal)) ?? "$0")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                
                // Historical Records
                VStack(alignment: .leading, spacing: 8) {
                    Text("歷史紀錄")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if expenseStore.expenses.isEmpty {
                        VStack {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text("尚無支出紀錄")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(expenseStore.expenses.sorted(by: { $0.date > $1.date })) { expense in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dateFormatter.string(from: expense.date))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(expense.category)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Text(numberFormatter.string(from: NSNumber(value: expense.amount)) ?? "$0")
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .contextMenu {
                                    Button("刪除", role: .destructive) {
                                        if let userId = authManager.currentUser?.uid {
                                            expenseStore.delete(expense: expense, userId: userId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Charts Section
                ExpenseChartsView(
                    categorySummaries: expenseStore.monthlyCategorySummaries
                )
                }
            }
            .navigationTitle("霓的記帳本")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("類別管理") {
                    showingCategoryManagement = true
                },
                trailing: Button("登出") {
                    authManager.signOut()
                }
            )
            .padding()
        }
        .onAppear {
            if let userId = authManager.currentUser?.uid {
                print("ContentView: User ID: \(userId)")
                expenseStore.startListening(userId: userId)
                categoryStore.startListening(userId: userId)
            } else {
                print("ContentView: No user ID found")
            }
        }
        .onDisappear {
            expenseStore.stopListening()
            categoryStore.stopListening()
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ExpenseStore())
        .environmentObject(CategoryStore())
}
