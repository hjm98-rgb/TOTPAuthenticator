import Foundation
import SwiftUI

class AccountStore: ObservableObject {
    static let shared = AccountStore()
    
    @Published var accounts: [TOTPAccount] = []
    @Published var tick: Int = 0
    
    private let accountsKey = "totp_accounts"
    private var timer: Timer?
    
    private init() {
        loadAccounts()
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.tick += 1
        }
    }
    
    func loadAccounts() {
        guard let data = KeychainService.shared.read(account: "totp_accounts") else {
            accounts = []
            return
        }
        do {
            accounts = try JSONDecoder().decode([TOTPAccount].self, from: data)
        } catch {
            accounts = []
        }
    }
    
    func saveAccounts() {
        do {
            let data = try JSONEncoder().encode(accounts)
            _ = KeychainService.shared.save(data, account: "totp_accounts")
        } catch {
            print("Failed to save accounts: \(error)")
        }
    }
    
    func addAccount(_ account: TOTPAccount) {
        accounts.append(account)
        saveAccounts()
    }
    
    func deleteAccount(_ account: TOTPAccount) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }
    
    func deleteAccount(at offsets: IndexSet) {
        accounts.remove(atOffsets: offsets)
        saveAccounts()
    }
}
