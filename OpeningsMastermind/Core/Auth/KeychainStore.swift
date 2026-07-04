//
//  KeychainStore.swift
//  OpeningsMastermind
//
//  Created by Christian Heise on 22.06.26.
//

import Foundation
import Security

/// A minimal wrapper around the iOS keychain for storing a single secret
/// string (e.g. an OAuth access token) under a fixed service/account key.
/// Used instead of `settings.json` because the token is sensitive and must
/// not land in the plaintext, iCloud-backed settings file.
struct KeychainStore {
    let service: String
    let account: String

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    func read() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        // Delete any existing item first so this is an idempotent upsert.
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
