import Foundation

struct CategorySummary: Identifiable {
    let id = UUID()
    let categoryName: String
    let total: Double
    let color: String // 用於圖表顏色
    
    init(categoryName: String, total: Double) {
        self.categoryName = categoryName
        self.total = total
        self.color = Self.generateColor(for: categoryName)
    }
    
    // 為每個類別分配固定的顏色
    private static func generateColor(for categoryName: String) -> String {
        // 預定義的顏色映射，確保每個類別都有固定顏色
        let colorMap: [String: String] = [
            "Rent": "DDA0DD",        // 紫色（你截圖中的顏色）
            "飲食": "FFEAA7",        // 黃色
            "交通": "45B7D1",        // 藍色
            "購物": "96CEB4",        // 綠色
            "娛樂": "FF6B6B",        // 紅色
            "醫療": "4ECDC4",        // 青綠色
            "其他": "98D8C8",        // 淺綠色
            "未分類": "FF6B6B"       // 紅色
        ]
        
        // 如果找到預定義顏色，使用它；否則使用預設顏色
        return colorMap[categoryName] ?? "85C1E9"
    }
}
