import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var displayName: String
    let registeredAt: Date
    var lastLoginAt: Date
    
    init(id: UUID = UUID(), email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.registeredAt = Date()
        self.lastLoginAt = Date()
    }
}

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let emailKey = "user_email"
    private let displayNameKey = "user_displayName"
    private let loggedInKey = "user_loggedIn"
    
    private init() {
        // Check if user was previously logged in (persistent across app launches)
        if UserDefaults.standard.bool(forKey: loggedInKey),
           let email = KeychainService.shared.readString(account: "user_email"),
           let name = KeychainService.shared.readString(account: "user_displayName") {
            self.currentUser = User(email: email, displayName: name)
            self.isLoggedIn = true
        }
    }
    
    func login(email: String, displayName: String) {
        let user = User(email: email, displayName: displayName)
        self.currentUser = user
        self.isLoggedIn = true
        
        // Persist to Keychain
        KeychainService.shared.saveString(email, account: "user_email")
        KeychainService.shared.saveString(displayName, account: "user_displayName")
        UserDefaults.standard.set(true, forKey: loggedInKey)
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        
        KeychainService.shared.delete(account: "user_email")
        KeychainService.shared.delete(account: "user_displayName")
        UserDefaults.standard.set(false, forKey: loggedInKey)
    }
}
