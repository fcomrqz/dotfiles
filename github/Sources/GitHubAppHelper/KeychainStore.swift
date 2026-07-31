import Foundation
import Security

struct KeychainStore {
    private let service: String
    private let account: String

    init(
        service: String = HelperPaths.keychainService,
        account: String = HelperPaths.keychainAccount
    ) {
        self.service = service
        self.account = account
    }

    func savePrivateKey(_ pem: Data) throws {
        _ = try PrivateKeyLoader.securityKey(fromPEM: pem)

        let query = baseQuery
        let attributes: [CFString: Any] = [kSecValueData: pem]
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return
        }
        if updateStatus != errSecItemNotFound {
            throw HelperError.keychain(updateStatus)
        }

        var insertion = query
        insertion[kSecValueData] = pem
        insertion[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(insertion as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw HelperError.keychain(addStatus)
        }
    }

    func loadPrivateKey() throws -> Data {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            throw HelperError.missingPrivateKey
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw HelperError.keychain(status)
        }
        return data
    }

    func containsPrivateKey() -> Bool {
        do {
            _ = try loadPrivateKey()
            return true
        } catch {
            return false
        }
    }

    func removePrivateKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw HelperError.keychain(status)
        }
    }

    private var baseQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
    }
}
