//
//  ExportService.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/9/5.
//

import Foundation
import UIKit

class ExportService: ObservableObject {
    
    // MARK: - CSV Export
    func exportToCSV(expenses: [Expense]) -> URL? {
        let sortedExpenses = expenses.sorted { $0.date < $1.date }
        
        print("ExportService: Creating CSV with \(sortedExpenses.count) expenses")
        
        var csvContent = "date,category,amount,note\n"
        
        for expense in sortedExpenses {
            let dateString = formatDateForCSV(expense.date)
            let category = escapeCSVField(expense.categoryName)
            let amount = String(expense.amount)
            let note = escapeCSVField(expense.note ?? "")
            
            csvContent += "\(dateString),\(category),\(amount),\(note)\n"
        }
        
        print("ExportService: CSV content length: \(csvContent.count) characters")
        return saveToTemporaryFile(content: csvContent, filename: "expenses.csv")
    }
    
    // MARK: - JSON Export
    func exportToJSON(expenses: [Expense]) -> URL? {
        let sortedExpenses = expenses.sorted { $0.date < $1.date }
        
        let exportData = sortedExpenses.map { expense in
            [
                "id": expense.id.uuidString,
                "date": ISO8601DateFormatter().string(from: expense.date),
                "category": expense.categoryName,
                "amount": expense.amount,
                "note": expense.note ?? ""
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            return saveToTemporaryFile(content: jsonString, filename: "expenses.json")
        } catch {
            print("Error creating JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    private func formatDateForCSV(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func escapeCSVField(_ field: String) -> String {
        // 如果欄位包含逗號、引號或換行符，需要用引號包圍並轉義引號
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        return field
    }
    
    private func saveToTemporaryFile(content: String, filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        print("ExportService: Saving file to: \(fileURL.absoluteString)")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("ExportService: File saved successfully")
            
            // 驗證檔案是否存在
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("ExportService: File exists at path")
                return fileURL
            } else {
                print("ExportService: File does not exist after writing")
                return nil
            }
        } catch {
            print("ExportService: Error writing file: \(error)")
            return nil
        }
    }
}
