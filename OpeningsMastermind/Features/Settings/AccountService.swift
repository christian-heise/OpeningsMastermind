//
//  AccountService.swift
//  OpeningsMastermind
//
//  Created by Christian Heise on 12.06.26.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpeningsMastermind", category: "AccountService")

/// Network IO for online chess accounts (Lichess / Chess.com), kept out of the
/// store and view model so they stay about state and presentation. Injected
/// into `AppData`; swap in a fake conforming to `AccountServicing` for tests.
protocol AccountServicing: Sendable {
    /// Whether an account with this username exists on the platform.
    func verifyUser(_ user: String, on platform: ChessPlatform) async -> Bool
    /// The player's blitz rating, if the platform exposes one.
    func fetchRating(for user: String, on platform: ChessPlatform) async -> Int?
}

struct LichessAccountService: AccountServicing {
    func verifyUser(_ user: String, on platform: ChessPlatform) async -> Bool {
        switch platform {
        case .chessDotCom:
            return true
        case .lichess:
            let urlString = "https://lichess.org/api/users/status?ids=\(user)"
            guard let url = URL(string: urlString) else {
                logger.error("Could not build Lichess user-status URL for user")
                return false
            }
            guard let (responseData, _) = try? await URLSession.shared.data(from: url) else {
                logger.warning("Lichess user-status request failed")
                return false
            }
            guard let decoded = try? JSONDecoder().decode([LichessUserResponse].self, from: responseData) else {
                logger.warning("Could not decode Lichess user-status response")
                return false
            }
            return !(decoded.first?.name.isEmpty ?? true)
        }
    }

    func fetchRating(for user: String, on platform: ChessPlatform) async -> Int? {
        switch platform {
        case .chessDotCom:
            return nil
        case .lichess:
            let urlString = "https://lichess.org/api/user/\(user)"
            guard let url = URL(string: urlString) else { return nil }
            guard let (responseData, _) = try? await URLSession.shared.data(from: url) else { return nil }
            guard let decoded = try? JSONDecoder().decode(LichessUserData.self, from: responseData) else { return nil }
            return decoded.perfs.blitz.rating
        }
    }

    private struct LichessUserResponse: Codable {
        let name: String
        let id: String
    }
}
