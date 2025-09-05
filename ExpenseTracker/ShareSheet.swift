//
//  ShareSheet.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/9/5.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        print("ShareSheet: Creating UIActivityViewController with \(items.count) items")
        
        // 如果沒有 items，創建一個空的 controller
        let controller = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
        
        // 針對 iPad 設定 popover
        if let popover = controller.popoverPresentationController {
            // 使用新的方式取得 window scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
            }
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // 加上完成回調
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                print("ShareSheet: Error during sharing: \(error)")
            } else {
                print("ShareSheet: Sharing completed: \(completed), activity: \(activityType?.rawValue ?? "nil")")
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {
        // 如果 items 有變化，重新創建 controller
        if items.count > 0 {
            print("ShareSheet: Updating with \(items.count) items")
            // 注意：UIActivityViewController 不支援動態更新，所以我們需要重新創建
            // 但這在 SwiftUI 中比較複雜，所以我們依賴 SwiftUI 的重新創建機制
        }
    }
}
