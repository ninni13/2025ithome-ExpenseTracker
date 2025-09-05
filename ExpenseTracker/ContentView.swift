//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/8/27.
//

import SwiftUI
import FirebaseFirestore

// 篩選狀態模型
struct FilterState {
    enum QuickPreset: String, CaseIterable {
        case all = "全部"
        case thisMonth = "本月"
        case lastMonth = "上月"
        case custom = "自訂"
    }
    
    var quickPreset: QuickPreset = .thisMonth
    var startDate: Date?
    var endDate: Date?
    var selectedCategoryIds: Set<String> = []
    
    // 初始化自訂日期的預設值
    mutating func setCustomDefaults() {
        let calendar = Calendar.current
        let now = Date()
        startDate = calendar.startOfDay(for: now)
        endDate = calendar.startOfDay(for: now)
    }
    
    // 計算實際的日期範圍
    var effectiveDateRange: (start: Date, end: Date)? {
        switch quickPreset {
        case .all:
            return nil
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            return (startOfMonth, startOfNextMonth)
        case .lastMonth:
            let calendar = Calendar.current
            let now = Date()
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? now
            let startOfThisMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfLastMonth, startOfThisMonth)
        case .custom:
            let calendar = Calendar.current
            let start = startDate ?? calendar.startOfDay(for: Date())
            let end = endDate ?? calendar.startOfDay(for: Date())
            // 將結束日期設為當天的結束時間（23:59:59）
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
            return (start, endOfDay)
        }
    }
    
    // 計算標題
    var title: String {
        switch quickPreset {
        case .all:
            return "全部歷史紀錄"
        case .thisMonth:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM"
            return "\(formatter.string(from: Date())) 歷史紀錄"
        case .lastMonth:
            let calendar = Calendar.current
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM"
            return "\(formatter.string(from: lastMonth)) 歷史紀錄"
        case .custom:
            return "自訂期間歷史紀錄"
        }
    }
}

// MARK: - Expense Model
struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let categoryId: String   // Firestore 的 categoryId
    let categoryName: String // 顯示用的名稱（去正規化）
    let date: Date
    let note: String?        // 備註欄位（選填）
    
    init(id: UUID = UUID(), amount: Double, categoryId: String, categoryName: String, date: Date, note: String? = nil) {
        self.id = id
        self.amount = amount
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.date = date
        self.note = note
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
    
    func add(amount: Double, categoryId: String, categoryName: String, date: Date, userId: String, note: String? = nil) {
        let expense = Expense(amount: amount, categoryId: categoryId, categoryName: categoryName, date: date, note: note)
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
            print("ExpenseStore: \(expense.categoryName) - $\(expense.amount) - \(expense.date)")
        }
        
        // 按類別分組並計算總額
        var categoryTotals: [String: Double] = [:]
        
        for expense in monthlyExpenses {
            categoryTotals[expense.categoryName, default: 0] += expense.amount
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
    @EnvironmentObject var budgetStore: BudgetStore
    @State private var amountText = ""
    @State private var selectedDate = Date()
    @State private var selectedCategoryId = ""
    @State private var noteText = ""
    @State private var showingCategoryManagement = false
    @State private var showingBudgetSettings = false
    
    // 篩選相關狀態
    @State private var filterState = FilterState()
    
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
    
    // 篩選後的支出列表
    private var filteredExpenses: [Expense] {
        let filtered = expenseStore.expenses.filter { expense in
            // 日期範圍篩選
            let isInDateRange: Bool
            if let dateRange = filterState.effectiveDateRange {
                isInDateRange = expense.date >= dateRange.start && expense.date <= dateRange.end
            } else {
                isInDateRange = true  // 沒有日期限制時，所有日期都通過
            }
            
            // 分類篩選
            let isInCategory: Bool
            if filterState.selectedCategoryIds.isEmpty {
                isInCategory = true  // 沒有選擇分類時，所有分類都通過
            } else {
                isInCategory = filterState.selectedCategoryIds.contains(expense.categoryId)
            }
            
            return isInDateRange && isInCategory
        }
        
        return filtered.sorted(by: { $0.date > $1.date })
    }
    
    // 篩選後的總支出
    private var filteredTotal: Double {
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    
    private var amount: Double {
        Double(amountText) ?? 0
    }
    
    private var isAddButtonDisabled: Bool {
        amount <= 0
    }
    
    // 截斷備註文字，超過 20 字加上 "..."
    private func truncateNote(_ note: String) -> String {
        if note.count <= 20 {
            return note
        } else {
            let index = note.index(note.startIndex, offsetBy: 20)
            return String(note[..<index]) + "..."
        }
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
                    
                    HStack {
                        Text("備註:")
                            .frame(width: 60, alignment: .leading)
                        TextField("備註（選填）", text: $noteText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button("新增紀錄") {
                        if let userId = authManager.currentUser?.uid {
                            if let category = categoryStore.categories.first(where: { $0.id == selectedCategoryId }) {
                                let note = noteText.isEmpty ? nil : noteText
                                print("ContentView: Adding expense - Amount: \(amount), Category: \(category.name), Date: \(selectedDate), Note: \(note ?? "nil")")
                                expenseStore.add(amount: amount, categoryId: selectedCategoryId, categoryName: category.name, date: selectedDate, userId: userId, note: note)
                                amountText = ""
                                selectedCategoryId = ""
                                noteText = ""
                            }
                        }
                    }
                    .disabled(isAddButtonDisabled || selectedCategoryId.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Budget and Monthly Total Section
                VStack(spacing: 12) {
                    // Monthly Total
                    HStack {
                        Text("本月總支出:")
                            .font(.headline)
                        Spacer()
                        Text(numberFormatter.string(from: NSNumber(value: expenseStore.monthlyTotal)) ?? "$0")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    // Budget Information
                    if budgetStore.monthlyBudget > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("本月預算:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(numberFormatter.string(from: NSNumber(value: budgetStore.monthlyBudget)) ?? "$0")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("剩餘金額:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                let remaining = budgetStore.getRemainingBudget(totalExpenses: expenseStore.monthlyTotal)
                                Text(numberFormatter.string(from: NSNumber(value: remaining)) ?? "$0")
                                    .font(.subheadline)
                                    .foregroundColor(remaining >= 0 ? .green : .red)
                            }
                            
                                                                    // Over Budget Warning
                                        if budgetStore.isOverBudget(totalExpenses: expenseStore.monthlyTotal) {
                                            HStack {
                                                Spacer()
                                                Text("⚠️ 已超支")
                                                    .font(.subheadline)
                                                    .foregroundColor(.red)
                                                    .fontWeight(.bold)
                                                Spacer()
                                            }
                                        }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        HStack {
                            Text("尚未設定預算")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("設定預算") {
                                showingBudgetSettings = true
                            }
                            .font(.caption)
                            .foregroundColor(.pink)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                                            // Filter Controls
                            VStack(alignment: .leading, spacing: 12) {
                                Text("篩選條件")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    // 快速篩選選項
                                    Picker("快速篩選", selection: $filterState.quickPreset) {
                                        ForEach(FilterState.QuickPreset.allCases, id: \.self) { preset in
                                            Text(preset.rawValue).tag(preset)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .onChange(of: filterState.quickPreset) { _, newValue in
                                        if newValue == .custom {
                                            filterState.setCustomDefaults()
                                        }
                                    }
                                    
                                    // 自訂日期選擇（只有選擇自訂時才顯示）
                                    if filterState.quickPreset == .custom {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("起始日期")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                DatePicker("", selection: Binding(
                                                    get: { filterState.startDate ?? Date() },
                                                    set: { filterState.startDate = $0 }
                                                ), displayedComponents: .date)
                                                    .labelsHidden()
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .leading) {
                                                Text("結束日期")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                DatePicker("", selection: Binding(
                                                    get: { filterState.endDate ?? Date() },
                                                    set: { filterState.endDate = $0 }
                                                ), displayedComponents: .date)
                                                    .labelsHidden()
                                            }
                                        }
                                    }
                                    
                                    // 分類選擇
                                    HStack {
                                        Text("分類:")
                                            .font(.subheadline)
                                        Spacer()
                                        Picker("分類", selection: Binding(
                                            get: { filterState.selectedCategoryIds.isEmpty ? "" : filterState.selectedCategoryIds.first! },
                                            set: { newValue in
                                                if newValue.isEmpty {
                                                    filterState.selectedCategoryIds = []
                                                } else {
                                                    filterState.selectedCategoryIds = [newValue]
                                                }
                                            }
                                        )) {
                                            Text("全部").tag("")
                                            ForEach(categoryStore.categories) { category in
                                                Text(category.name).tag(category.id)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                    }
                                    
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }

                            // Historical Records
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(filterState.title)
                                        .font(.headline)
                                    Spacer()
                                    Text("篩選總計: \(numberFormatter.string(from: NSNumber(value: filteredTotal)) ?? "$0")")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal)
                    
                    if filteredExpenses.isEmpty {
        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text("無符合篩選條件的紀錄")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExpenses) { expense in
                                VStack(alignment: .leading, spacing: 4) {
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
                                    
                                    // 顯示備註（如果有且不為空）
                                    if let note = expense.note, !note.isEmpty {
                                        HStack {
                                            Text(truncateNote(note))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                    }
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
                leading: Menu {
                    Button("類別管理") {
                        showingCategoryManagement = true
                    }
                    Button("預算管理") {
                        showingBudgetSettings = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("管理")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
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
                budgetStore.startListening(userId: userId)
            } else {
                print("ContentView: No user ID found")
            }
        }
        .onDisappear {
            expenseStore.stopListening()
            categoryStore.stopListening()
            budgetStore.stopListening()
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
        }
        .sheet(isPresented: $showingBudgetSettings) {
            BudgetSettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ExpenseStore())
        .environmentObject(CategoryStore())
        .environmentObject(BudgetStore())
}
