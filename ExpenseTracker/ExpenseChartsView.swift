import SwiftUI
import Charts

// 圓餅圖樣式枚舉
enum ChartStyle: String, CaseIterable {
    case standard = "標準"
    case donut = "甜甜圈"
    case threeD = "3D"
    case gradient = "漸層"
}

struct ExpenseChartsView: View {
    let categorySummaries: [CategorySummary]
    @State private var selectedChartStyle: ChartStyle = .standard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 標題
            Text("支出統計")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if categorySummaries.isEmpty {
                // 無數據時的顯示
                VStack {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("尚無支出數據")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 圓餅圖樣式選擇器
                HStack {
                    Text("圓餅圖樣式")
                        .font(.headline)
                    Spacer()
                    Picker("樣式", selection: $selectedChartStyle) {
                        ForEach(ChartStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                
                // 圓餅圖
                Chart(categorySummaries) { summary in
                    SectorMark(
                        angle: .value("金額", summary.total),
                        innerRadius: selectedChartStyle == .donut ? .ratio(0.4) : .ratio(0),
                        angularInset: selectedChartStyle == .threeD ? 4 : 2
                    )
                    .foregroundStyle(chartStyleColor(for: summary))
                    .cornerRadius(selectedChartStyle == .threeD ? 8 : 4)
                    .shadow(radius: selectedChartStyle == .threeD ? 3 : 0)
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                // 統計摘要
                VStack(alignment: .leading, spacing: 12) {
                    Text("統計摘要")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(categorySummaries.sorted(by: { $0.total > $1.total })) { summary in
                            HStack {
                                Circle()
                                    .fill(Color(hex: summary.color))
                                    .frame(width: 12, height: 12)
                                
                                Text(summary.categoryName)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(formatCurrency(summary.total))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // 根據樣式返回顏色
    private func chartStyleColor(for summary: CategorySummary) -> Color {
        switch selectedChartStyle {
        case .gradient:
            return Color(hex: summary.color).opacity(0.8)
        default:
            return Color(hex: summary.color)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// 顏色擴展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ExpenseChartsView(
        categorySummaries: [
            CategorySummary(categoryName: "飲食", total: 2500),
            CategorySummary(categoryName: "交通", total: 800),
            CategorySummary(categoryName: "娛樂", total: 1200)
        ]
    )
}
