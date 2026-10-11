import SwiftUI

@main
struct TOTPAuthenticatorApp: App {
    @StateObject private var userSession = UserSession.shared
    @StateObject private var accountStore = AccountStore.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userSession)
                .environmentObject(accountStore)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var userSession: UserSession
    
    var body: some View {
        Group {
            if userSession.isLoggedIn {
                MainListView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: userSession.isLoggedIn)
    }
}
