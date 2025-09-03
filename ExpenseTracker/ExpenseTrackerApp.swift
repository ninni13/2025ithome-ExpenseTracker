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
    

    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isSignedIn {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(expenseStore)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                print("App appeared, isSignedIn: \(authManager.isSignedIn)")
            }
        }
    }
}
