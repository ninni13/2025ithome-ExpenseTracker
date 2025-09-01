//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/8/27.
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var expenseStore = ExpenseStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(expenseStore)
        }
    }
}
