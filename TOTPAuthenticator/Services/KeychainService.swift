import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.cert.account.t260901214911"
    
    private init() {}
    
    // MARK: - Save
    func save(_ data: Data, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Delete existing first
        SecItemDelete(query as CFDictionary)
        
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func saveString(_ string: String, account: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, account: account)
    }
    
    // MARK: - Read
    func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }
    
    func readString(account: String) -> String? {
        guard let data = read(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Check existence
    func exists(account: String) -> Bool {
        return read(account: account) != nil
    }
}
