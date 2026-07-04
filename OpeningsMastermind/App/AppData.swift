//
//  AppData.swift
//  OpeningsMastermind
//
//  Created by Christian Heise on 11.06.26.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpeningsMastermind", category: "AppData")

/// The single source of truth for app-wide model state, and the only object
/// that persists settings to disk. Injected into the environment and into
/// view models (e.g. `SettingsViewModel`).
///
/// Network IO for online accounts currently lives here; it is extracted into a
/// dedicated `AccountService` in a later step.
@MainActor
@Observable
class AppData {
    var settings: SettingsData

    @ObservationIgnored let accountService: AccountServicing

    /// Owns the user's Lichess OAuth session. The token it vends is required
    /// for opening-explorer requests (Lichess gated that host behind auth).
    let lichessAuth: LichessAuthService

    init(settings: SettingsData? = nil,
         accountService: AccountServicing = LichessAccountService(),
         lichessAuth: LichessAuthService? = nil) {
        self.settings = settings ?? AppData.load() ?? SettingsData()
        self.accountService = accountService
        self.lichessAuth = lichessAuth ?? LichessAuthService()
    }

    // MARK: - Persistence

    func save() {
        let filename = AppData.getDocumentsDirectory().appendingPathComponent("settings.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let encoded = try encoder.encode(settings)
            try encoded.write(to: filename, options: .atomic)
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Loads persisted settings, or `nil` if none exist yet or the file is
    /// unreadable. A missing file is expected on first launch and is not
    /// logged; a present-but-corrupt file is logged and moved aside so it
    /// doesn't keep failing to load on every future launch.
    ///
    /// Also called from `OpeningsMastermindApp.init()` to read the
    /// analytics/crash-log opt-ins before `TelemetryDeck.initialize(config:)`.
    static func load() -> SettingsData? {
        let filename = getDocumentsDirectory().appendingPathComponent("settings.json")
        do {
            let fileData = try Data(contentsOf: filename)
            return try JSONDecoder().decode(SettingsData.self, from: fileData)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        } catch {
            logger.error("Failed to load settings, resetting to defaults: \(error.localizedDescription, privacy: .public)")
            quarantineCorruptedSettingsFile(at: filename)
            return nil
        }
    }

    /// Moves an unreadable settings file out of the way so a future save
    /// doesn't keep failing to load it on every launch, while letting the
    /// app proceed with default settings instead.
    private static func quarantineCorruptedSettingsFile(at url: URL) {
        let quarantineURL = url.deletingPathExtension().appendingPathExtension("corrupted.json")
        do {
            _ = try FileManager.default.replaceItemAt(quarantineURL, withItemAt: url)
        } catch {
            logger.error("Failed to quarantine corrupted settings file: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Online account details

    /// Signs the user in to Lichess via OAuth (required for opening-explorer
    /// access), then records the resulting username and refreshes their rating.
    /// Used by both Settings and the Explorer's inline sign-in prompt.
    @MainActor
    func signInToLichess() async throws {
        let username = try await lichessAuth.signIn()
        settings.lichessName = username
        save()
        await updateAccountDetails(for: .lichess)
    }

    /// Signs out of Lichess and clears the linked account details.
    @MainActor
    func signOutOfLichess() {
        lichessAuth.signOut()
        settings.lichessName = nil
        settings.playerRating = nil
        save()
    }

    func updateAllAccountDetails() async {
        if settings.lichessName != nil {
            await updateAccountDetails(for: .lichess)
        }
        if settings.chessComName != nil {
            await updateAccountDetails(for: .chessDotCom)
        }
    }

    func updateAccountDetails(for platform: ChessPlatform) async {
        switch platform {
        case .chessDotCom:
            break
        case .lichess:
            guard let name = settings.lichessName else { return }
            guard let rating = await accountService.fetchRating(for: name, on: .lichess) else {
                logger.warning("Could not fetch Lichess rating for the connected account")
                return
            }
            await MainActor.run {
                settings.playerRating = rating
            }
            save()
        }
    }
}
