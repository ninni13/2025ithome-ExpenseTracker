# ExpenseTracker

一個使用 **SwiftUI** 開發的簡易記帳 App，作為 [iThome 鐵人賽 2025 — 30 天 Vibe Coding：全端 × 機器學習的實作挑戰](https://ithelp.ithome.com.tw/) 系列的 Side Project。

## 功能特色 (Day 3 MVP)
- 新增支出：輸入金額與日期，立即顯示在清單中
- 清單顯示：每筆支出會顯示「日期 | 金額」
- 支援左滑刪除
- 自動加總「本月總支出」
- 使用 **UserDefaults + Codable** 持久化資料，重開 App 後紀錄仍存在

## 技術棧
- **SwiftUI**
- **iOS 17+**
- **Xcode 15+**
- 資料儲存：`UserDefaults`（Key: `com.vibe.expenses`）