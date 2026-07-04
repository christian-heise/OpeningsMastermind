//
//  SettingsViewModel.swift
//  OpeningsMastermind
//
//  Created by Christian Heise on 11.06.26.
//

import SwiftUI
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpeningsMastermind", category: "SettingsViewModel")

/// Handles the editing-and-verification concerns of the Settings screen.
/// Mutates the shared `AppData` store and asks it to persist. Every settable
/// property here persists on write, so the view binds to the view model rather
/// than to `appData.settings` directly and persistence stays in one place.
@MainActor
@Observable
class SettingsViewModel {
    let appData: AppData

    init(appData: AppData) {
        self.appData = appData
    }

    // MARK: - Persisted settings

    var engineOn: Bool {
        get { appData.settings.engineOn }
        set { appData.settings.engineOn = newValue; appData.save() }
    }

    var moveDelay_ms: Double {
        get { appData.settings.moveDelay_ms }
        set { appData.settings.moveDelay_ms = newValue; appData.save() }
    }

    var boardColorWhite: Color {
        get { appData.settings.boardColorRGB.white.getColor() }
        set { appData.settings.boardColorRGB.white = newValue.rgbValues; appData.save() }
    }

    var boardColorBlack: Color {
        get { appData.settings.boardColorRGB.black.getColor() }
        set { appData.settings.boardColorRGB.black = newValue.rgbValues; appData.save() }
    }

    var lichessName: String? { appData.settings.lichessName }

    var isSignedInToLichess: Bool { appData.lichessAuth.isSignedIn }

    var language: AppLanguage {
        get { appData.settings.language }
        set { appData.settings.language = newValue; appData.save() }
    }

    /// Toggling this immediately reconfigures TelemetryDeck and
    /// `CrashReporter` via `AnalyticsService`, so the change takes effect
    /// without restarting the app.
    var analyticsEnabled: Bool {
        get { appData.settings.analyticsEnabled }
        set {
            appData.settings.analyticsEnabled = newValue
            appData.save()
            AnalyticsService.configure(analyticsEnabled: newValue)
        }
    }

    // MARK: - Actions

    func resetColor() {
        appData.settings.boardColorRGB = BoardColorRGB()
        appData.save()
    }

    func resetMoveDelay() {
        appData.settings.moveDelay_ms = 300
        appData.save()
    }

    /// Signs in to Lichess via OAuth, which records the username and rating and
    /// enables the opening explorer. Cancellation is silent.
    func signInToLichess() async {
        do {
            try await appData.signInToLichess()
        } catch LichessAuthError.cancelled {
            // User dismissed the sign-in sheet.
        } catch {
            logger.warning("Lichess sign-in failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func signOutOfLichess() {
        appData.signOutOfLichess()
    }

    func resetAccount(for platform: ChessPlatform) {
        switch platform {
        case .chessDotCom:
            appData.settings.chessComName = nil
        case .lichess:
            appData.settings.lichessName = nil
            appData.settings.playerRating = nil
        }
        appData.save()
    }

    func setAccountName(to user: String, for platform: ChessPlatform) async {
        guard await appData.accountService.verifyUser(user, on: platform) else { return }

        await MainActor.run {
            switch platform {
            case .chessDotCom:
                appData.settings.chessComName = user
            case .lichess:
                appData.settings.lichessName = user
            }
        }
        appData.save()
        await appData.updateAllAccountDetails()
    }
}
