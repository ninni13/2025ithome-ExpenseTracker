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
    let date: Date
    let categoryId: String
    let categoryName: String
    
    init(id: UUID = UUID(), amount: Double, date: Date, categoryId: String, categoryName: String) {
        self.id = id
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.categoryName = categoryName
    }
}

// MARK: - ExpenseStore
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    private let firestoreService = FirestoreService()
    private var listenerRegistration: FirebaseFirestore.ListenerRegistration?
    
    func startListening(userId: String) {
        print("ExpenseStore: Starting to listen for expenses for user: \(userId)")
        listenerRegistration = firestoreService.listenToExpenses(userId: userId) { [weak self] expenses in
            print("ExpenseStore: Received \(expenses.count) expenses from Firestore")
            DispatchQueue.main.async {
                self?.expenses = expenses
                print("ExpenseStore: Updated expenses array with \(expenses.count) items")
            }
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func add(amount: Double, date: Date, categoryId: String, categoryName: String, userId: String) {
        let expense = Expense(amount: amount, date: date, categoryId: categoryId, categoryName: categoryName)
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
                                expenseStore.add(amount: amount, date: selectedDate, categoryId: category.id, categoryName: category.name, userId: userId)
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
                
                // Expenses List
                List {
                    ForEach(expenseStore.expenses.sorted(by: { $0.date > $1.date })) { expense in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateFormatter.string(from: expense.date))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(expense.categoryName)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Text(numberFormatter.string(from: NSNumber(value: expense.amount)) ?? "$0")
                                .fontWeight(.medium)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let expense = expenseStore.expenses.sorted(by: { $0.date > $1.date })[index]
                            if let userId = authManager.currentUser?.uid {
                                expenseStore.delete(expense: expense, userId: userId)
                            }
                        }
                    }
                }
            }
            .navigationTitle("記帳本")
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
