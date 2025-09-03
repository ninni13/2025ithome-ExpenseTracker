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
}

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var amountText = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory = "一般"
    
    private let categories = ["一般", "飲食", "交通", "購物", "娛樂", "醫療", "其他"]
    
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
                        Picker("分類", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("日期:")
                            .frame(width: 60, alignment: .leading)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    Button("新增紀錄") {
                        if let userId = authManager.currentUser?.uid {
                            expenseStore.add(amount: amount, category: selectedCategory, date: selectedDate, userId: userId)
                            amountText = ""
                        }
                    }
                    .disabled(isAddButtonDisabled)
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
                                Text(expense.category)
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
            .navigationBarItems(trailing: Button("登出") {
                authManager.signOut()
            })
            .padding()
        }
        .onAppear {
            if let userId = authManager.currentUser?.uid {
                expenseStore.startListening(userId: userId)
            }
        }
        .onDisappear {
            expenseStore.stopListening()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ExpenseStore())
}
