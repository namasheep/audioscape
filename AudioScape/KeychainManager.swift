import Foundation
import Security

class KeychainManager {

    static let shared = KeychainManager()
    
    private let serviceIdentifier = "com.yourapp.appname"
    
    func saveAccessToken(_ accessToken: String, forUser userIdentifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: userIdentifier,
            kSecValueData as String: accessToken.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func loadAccessToken(forUser userIdentifier: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: userIdentifier,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let retrievedData = item as? Data {
            return String(data: retrievedData, encoding: .utf8)
        }
        
        return nil
    }
    
    func deleteAccessToken(forUser userIdentifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: userIdentifier
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
