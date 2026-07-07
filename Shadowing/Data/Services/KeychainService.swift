import Foundation
import Security

private enum KeychainKey {
    static let service = "com.shadowing.auth"
    static let refreshToken = "refreshToken"
}

@MainActor
final class KeychainService {
    
    static let shared = KeychainService()
    
    private init() {}
    
    var refreshToken: String? {
        get { read(key: KeychainKey.refreshToken) }
        set { write(newValue, for: KeychainKey.refreshToken) }
    }
    
    func clear() {
        delete(key: KeychainKey.refreshToken)
    }
    
    private func write(_ value: String?, for key: String) {
        guard let value else {
            delete(key: key)
            return
        }
        
        let data = Data(value.utf8)
        let query = baseQuery(for: key)
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
            case errSecSuccess:
                _ = SecItemUpdate(
                    query as CFDictionary,
                    [kSecValueData: data] as CFDictionary
                )
                
            case errSecItemNotFound:
                var addQuery = query
                addQuery[kSecValueData] = data
                addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                
                _ = SecItemAdd(addQuery as CFDictionary, nil)
                
            default:
                break
        }
    }
    
    private func read(key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    private func delete(key: String) -> Bool {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    private func baseQuery(for key: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: KeychainKey.service,
            kSecAttrAccount: key
        ]
    }
}
