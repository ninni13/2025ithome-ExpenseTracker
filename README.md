# ExpenseTracker - 記帳本 App

一個使用 **SwiftUI** 開發的簡易記帳 App，作為 [iThome 鐵人賽 2025 — 30 天 Vibe Coding：全端 × 
機器學習的實作挑戰](https://ithelp.ithome.com.tw/) 系列的 Side Project。

## 功能特色

### 🔐 使用者認證
- Google 帳號登入
- 自動登入狀態檢查
- 安全登出功能

### 💰 記帳功能
- 金額輸入（支援小數點）
- 支出分類選擇
- 日期選擇（預設今天）
- 即時支出清單
- 本月總支出計算

### ☁️ 雲端儲存
- Firebase Firestore 即時資料同步
- 使用者專屬資料隔離
- 自動資料備份

## 技術架構

- **前端**: SwiftUI (iOS 17+)
- **認證**: Firebase Authentication + Google Sign-In
- **資料庫**: Cloud Firestore
- **架構**: MVVM + ObservableObject

## 安裝設定

### 1. 前置需求
- Xcode 15.0+
- iOS 17.0+
- Firebase 專案
- Google Sign-In 設定

### 2. Firebase 設定
1. 在 [Firebase Console](https://console.firebase.google.com/) 建立新專案
2. 啟用 Authentication 和 Firestore
3. 設定 Google Sign-In 提供者
4. 下載 `GoogleService-Info.plist` 並放入專案

### 3. 依賴安裝
專案使用 Swift Package Manager 管理依賴：
- Firebase iOS SDK
- Google Sign-In iOS SDK

### 4. 專案設定
1. 在 Xcode 中開啟專案
2. 確保 Bundle Identifier 與 Firebase 專案一致
3. 設定 Signing & Capabilities
4. 建置並運行

## 資料結構

### Firestore 集合結構
```
users/{userId}/expenses/{expenseId}
```

### Expense 文件欄位
- `id`: 唯一識別碼 (String)
- `amount`: 金額 (Double)
- `category`: 分類 (String)
- `date`: 日期 (Timestamp)

## 使用說明

1. **首次啟動**: 點擊「使用 Google 登入」按鈕
2. **新增支出**: 輸入金額、選擇分類和日期，點擊「新增紀錄」
3. **查看清單**: 所有支出會即時顯示在清單中
4. **刪除支出**: 左滑支出項目即可刪除
5. **登出**: 點擊右上角「登出」按鈕

## 注意事項

- 需要網路連線才能使用
- 首次登入需要 Google 帳號授權
- 所有資料會自動同步到雲端
- 支援離線使用（資料會在下一次連線時同步）

## 功能演進 
### Day 3 (MVP)
- 新增支出：輸入金額與日期，立即顯示在清單中
- 清單顯示：每筆支出會顯示「日期 | 金額」
- 支援左滑刪除
- 自動加總「本月總支出」
- 使用 UserDefaults + Codable 持久化資料，重開 App 後紀錄仍存在

### Day 4 (雲端同步)
- 加入 Google 登入（Firebase Authentication）
- 所有資料改存 Cloud Firestore
- 每位使用者的支出獨立存放在 users/{uid}/expenses
- 支援跨裝置同步，換機或刪除 App 只要重新登入 Google，紀錄就能回來

### Day 5 (分類／標籤管理)
- 新增「類別」功能：可建立、重新命名、刪除類別
- Firestore 結構改為每位使用者自有類別 users/{uid}/categories，支出放 users/{uid}/expenses
- 新增支出必選類別；支出文件同時寫入 categoryId 與 categoryName（去正規化，列表直接顯示名稱）
- 類別改名時，批次更新該使用者所有相關支出的 categoryName
- 若類別已被使用，阻擋刪除並提示使用者

## 技術棧
- **SwiftUI**
- **iOS 17+**
- **Xcode 15+**
- 資料儲存：UserDefaults (Day 3 MVP) → Firebase Firestore (Day 4)