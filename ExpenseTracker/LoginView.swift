import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // 粉色系漸層背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.15),
                    Color.orange.opacity(0.1),
                    Color.pink.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 主要內容區域
                VStack(spacing: 24) {
                    // App Logo 和名稱
                    VStack(spacing: 16) {
                        // 簡化的 App Icon
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.pink)
                        
                        VStack(spacing: 4) {
                            Text("ExpenseTracker")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("iThome 鐵人賽 2025 作品")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("霓霓的 30 天 Vibe Coding 挑戰")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("全端 × 機器學習的實作挑戰")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 登入按鈕區域
                VStack(spacing: 20) {
                    // 美化的 Google 登入按鈕 - 粉色系
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack(spacing: 16) {
                            // 使用系統圖示作為 Google 標誌
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.pink)
                            
                            Text("使用 Google 帳號登入")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    

                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // 底部資訊
                VStack(spacing: 8) {
                    Text("iThome 鐵人賽 2025")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
