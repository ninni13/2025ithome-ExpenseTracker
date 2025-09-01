//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/8/27.
//

import SwiftUI

// MARK: - Expense Model
struct Expense: Identifiable, Codable {
    let id = UUID()
    let amount: Double
    let date: Date
}

// MARK: - ExpenseStore
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    private let userDefaultsKey = "com.vibe.expenses"
    
    init() {
        load()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decodedExpenses
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func add(amount: Double, date: Date) {
        let expense = Expense(amount: amount, date: date)
        expenses.append(expense)
        save()
    }
    
    func delete(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        save()
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
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var amountText = ""
    @State private var selectedDate = Date()
    
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
                        Text("日期:")
                            .frame(width: 60, alignment: .leading)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    Button("新增紀錄") {
                        expenseStore.add(amount: amount, date: selectedDate)
                        amountText = ""
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
                            Text(dateFormatter.string(from: expense.date))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(numberFormatter.string(from: NSNumber(value: expense.amount)) ?? "$0")
                                .fontWeight(.medium)
                        }
                    }
                    .onDelete(perform: expenseStore.delete)
                }
            }
            .navigationTitle("記帳本")
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ExpenseStore())
}
