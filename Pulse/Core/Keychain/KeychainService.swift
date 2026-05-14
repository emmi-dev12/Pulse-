import Foundation
import Security

enum KeychainError: Error {
    case unexpectedData
    case unhandledError(OSStatus)
}

final class KeychainService {
    private let service = "com.pulse.app"

    enum Key: String {
        case convexURL          = "pulse.convex.url"
        case convexDeployKey    = "pulse.convex.deploymentKey"
        case composioAPIKey     = "pulse.composio.apiKey"
    }

    var credentialsComplete: Bool {
        load(.convexURL) != nil &&
        load(.convexDeployKey) != nil &&
        load(.composioAPIKey) != nil
    }

    func load(_ key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    @discardableResult
    func save(_ value: String, for key: Key) -> Result<Void, KeychainError> {
        guard let data = value.data(using: .utf8) else {
            return .failure(.unexpectedData)
        }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            return .failure(.unhandledError(status))
        }
        return .success(())
    }

    @discardableResult
    func delete(_ key: Key) -> Result<Void, KeychainError> {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            return .failure(.unhandledError(status))
        }
        return .success(())
    }

    func deleteAll() {
        Key.allCases.forEach { delete($0) }
    }
}

extension KeychainService.Key: CaseIterable {}
