//
//  AppDataTests.swift
//  OpeningsMastermindTests
//

import Testing
import Foundation
@testable import OpeningsMastermind

/// Serialized: these tests share the on-disk settings.json in the simulator's
/// Documents directory, since `AppData`'s persistence paths aren't injectable.
@Suite(.serialized)
@MainActor
struct AppDataTests {

    private var settingsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("settings.json")
    }

    private var quarantineURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("settings.corrupted.json")
    }

    init() {
        try? FileManager.default.removeItem(at: settingsURL)
        try? FileManager.default.removeItem(at: quarantineURL)
    }

    // MARK: - Load

    @Test func loadsDefaultsWhenNoFileExists() {
        let appData = AppData()
        #expect(appData.settings == SettingsData())
    }

    @Test func saveAndReloadRoundTrips() {
        let appData = AppData()
        appData.settings.engineOn = false
        appData.settings.lichessName = "testuser"
        appData.save()

        let reloaded = AppData()
        #expect(reloaded.settings.engineOn == false)
        #expect(reloaded.settings.lichessName == "testuser")
    }

    @Test func corruptedFileIsQuarantinedAndDefaultsAreUsed() throws {
        try "not valid json".write(to: settingsURL, atomically: true, encoding: .utf8)

        let appData = AppData()

        #expect(appData.settings == SettingsData())
        #expect(FileManager.default.fileExists(atPath: quarantineURL.path))
        #expect(!FileManager.default.fileExists(atPath: settingsURL.path))
    }

    @Test func missingBoardColorFieldDoesNotResetOtherSettings() throws {
        let json = #"{"lichessName":"alice","engineOn":false}"#
        try json.write(to: settingsURL, atomically: true, encoding: .utf8)

        let appData = AppData()

        #expect(appData.settings.lichessName == "alice")
        #expect(appData.settings.engineOn == false)
        #expect(appData.settings.boardColorRGB == BoardColorRGB())
    }

    // MARK: - Account details

    @Test func updateAccountDetailsPersistsRatingOnSuccess() async {
        var settings = SettingsData()
        settings.lichessName = "alice"
        let appData = AppData(settings: settings, accountService: FakeAccountService(ratingToReturn: 1800))

        await appData.updateAccountDetails(for: .lichess)
        #expect(appData.settings.playerRating == 1800)

        let reloaded = AppData()
        #expect(reloaded.settings.playerRating == 1800)
    }

    @Test func updateAccountDetailsLeavesRatingUnchangedOnFailure() async {
        var settings = SettingsData()
        settings.lichessName = "alice"
        settings.playerRating = 1500
        let appData = AppData(settings: settings, accountService: FakeAccountService(ratingToReturn: nil))

        await appData.updateAccountDetails(for: .lichess)
        #expect(appData.settings.playerRating == 1500)
    }
}

private struct FakeAccountService: AccountServicing {
    var ratingToReturn: Int?

    func verifyUser(_ user: String, on platform: ChessPlatform) async -> Bool { true }
    func fetchRating(for user: String, on platform: ChessPlatform) async -> Int? { ratingToReturn }
}
