//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Nini on 2025/8/27.
//

import SwiftUI
import Firebase

@main
struct ExpenseTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var expenseStore = ExpenseStore()
    @StateObject private var categoryStore = CategoryStore()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isSignedIn {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(expenseStore)
                        .environmentObject(categoryStore)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
        }
    }
}
