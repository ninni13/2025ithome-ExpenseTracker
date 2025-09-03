import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: FirebaseAuth.User?
    
    init() {
        print("AuthManager init called")
        
        // 檢查是否已經登入
        if let user = Auth.auth().currentUser {
            print("Found existing user: \(user.uid)")
            self.currentUser = user
            self.isSignedIn = true
        } else {
            print("No existing user found")
        }
    }
    
    func signInWithGoogle() {
        // 從 GoogleService-Info.plist 讀取 CLIENT_ID
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            print("Failed to read CLIENT_ID from GoogleService-Info.plist")
            return
        }
        
        print("Using CLIENT_ID from plist: \(clientID)")
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("Error domain: \(nsError.domain)")
                    print("Error code: \(nsError.code)")
                    print("Error userInfo: \(nsError.userInfo)")
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    print("Firebase Auth error: \(error.localizedDescription)")
                    return
                }
                
                if let user = result?.user {
                    self?.currentUser = user
                    self?.isSignedIn = true
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
            self.isSignedIn = false
            print("Successfully signed out and cleared cache")
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
    
    func clearAllCache() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
            self.isSignedIn = false
            print("All cache cleared")
        } catch {
            print("Clear cache error: \(error.localizedDescription)")
        }
    }
}
