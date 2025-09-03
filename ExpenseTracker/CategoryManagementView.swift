import SwiftUI
import Firebase

struct CategoryManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var categoryStore: CategoryStore
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var showingRenameAlert = false
    @State private var categoryToRename: Category?
    @State private var newName = ""
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if categoryStore.categories.isEmpty {
                    // 空狀態
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("還沒有任何類別")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("點擊右上角 + 按鈕新增第一個類別")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 類別列表
                    List {
                        ForEach(categoryStore.categories) { category in
                            Button(action: {
                                categoryToRename = category
                                newName = category.name
                                showingRenameAlert = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("建立於 \(formatDate(category.createdAt))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("重新命名") {
                                    categoryToRename = category
                                    newName = category.name
                                    showingRenameAlert = true
                                }
                                .tint(.blue)
                                
                                Button("刪除") {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("類別管理")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button(action: {
                showingAddCategory = true
            }) {
                Image(systemName: "plus")
            })
            .onAppear {
                if let userId = authManager.currentUser?.uid {
                    categoryStore.startListening(userId: userId)
                }
            }
            .onDisappear {
                categoryStore.stopListening()
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(
                isPresented: $showingAddCategory,
                categoryName: $newCategoryName,
                onAdd: { name in
                    if let userId = authManager.currentUser?.uid {
                        categoryStore.add(name: name, userId: userId) { success, errorMessage in
                            if !success {
                                self.errorMessage = errorMessage ?? "新增類別失敗"
                                self.showingErrorAlert = true
                            }
                        }
                        newCategoryName = ""
                    }
                }
            )
        }
        .alert("重新命名類別", isPresented: $showingRenameAlert) {
            TextField("類別名稱", text: $newName)
            Button("取消", role: .cancel) { }
            Button("確定") {
                if let category = categoryToRename, let userId = authManager.currentUser?.uid {
                    categoryStore.rename(id: category.id, newName: newName, userId: userId) { success, errorMessage in
                        if !success {
                            self.errorMessage = errorMessage ?? "重新命名失敗"
                            self.showingErrorAlert = true
                        }
                    }
                }
            }
        } message: {
            Text("請輸入新的類別名稱")
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                if let category = categoryToDelete, let userId = authManager.currentUser?.uid {
                    categoryStore.delete(id: category.id, userId: userId) { success, errorMessage in
                        if !success {
                            self.errorMessage = errorMessage ?? "刪除失敗"
                            self.showingErrorAlert = true
                        }
                    }
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("確定要刪除類別「\(category.name)」嗎？\n\n注意：如果此類別已被使用，將無法刪除。")
            }
        }
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AddCategoryView: View {
    @Binding var isPresented: Bool
    @Binding var categoryName: String
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("新增類別")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("類別名稱", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("新增") {
                    if !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onAdd(categoryName.trimmingCharacters(in: .whitespacesAndNewlines))
                        isPresented = false
                    }
                }
                .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

#Preview {
    CategoryManagementView()
        .environmentObject(AuthManager())
        .environmentObject(CategoryStore())
}
