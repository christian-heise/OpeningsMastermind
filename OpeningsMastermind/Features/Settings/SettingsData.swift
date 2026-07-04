//
//  SettingsData.swift
//  OpeningsMastermind
//
//  Created by Christian Heise on 12.06.26.
//

import Foundation

struct SettingsData: Codable, Equatable {
    var boardColorRGB = BoardColorRGB()

    var lichessName: String?
    var chessComName: String?
    var playerRating: Int?

    var engineOn: Bool = true

    var moveDelay_ms: Double = 300
    var moveAnimation: Bool = false

    var language: AppLanguage = .auto

    var analyticsEnabled: Bool = false

    /// Marketing version (`CFBundleShortVersionString`) whose "What's New" screen
    /// the user has already seen. `nil` means it has never been shown. When it
    /// differs from the running app's version, `ContentView` presents the
    /// one-time update splash and writes the current version back here.
    var lastSeenWhatsNewVersion: String?

    enum CodingKeys: String, CodingKey {
        case boardColorRGB, lichessName, chessComName, playerRating, engineOn, language
        case moveDelay_ms = "delay"
        case moveAnimation = "animation"
        case analyticsEnabled
        case lastSeenWhatsNewVersion
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boardColorRGB = try container.decodeIfPresent(BoardColorRGB.self, forKey: .boardColorRGB) ?? BoardColorRGB()
        lichessName = try container.decodeIfPresent(String.self, forKey: .lichessName)
        chessComName = try container.decodeIfPresent(String.self, forKey: .chessComName)
        playerRating = try container.decodeIfPresent(Int.self, forKey: .playerRating)
        engineOn = try container.decodeIfPresent(Bool.self, forKey: .engineOn) ?? true
        moveDelay_ms = try container.decodeIfPresent(Double.self, forKey: .moveDelay_ms) ?? 300
        moveAnimation = try container.decodeIfPresent(Bool.self, forKey: .moveAnimation) ?? false
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .auto
        analyticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .analyticsEnabled) ?? false
        lastSeenWhatsNewVersion = try container.decodeIfPresent(String.self, forKey: .lastSeenWhatsNewVersion)
    }
}

/// The app's display language. `.auto` follows the system language; the
/// others force a locale via `.environment(\.locale, ...)` regardless of the
/// device's system language.
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case auto, english, german

    var id: Self { self }

    /// `nil` means "follow the system locale".
    var locale: Locale? {
        switch self {
        case .auto: return nil
        case .english: return Locale(identifier: "en")
        case .german: return Locale(identifier: "de")
        }
    }
}

struct BoardColorRGB: Codable, Equatable {
    var white = [255,255,255]
    var black = [171, 133, 102]

    // green: [93, 132, 101]
    // orange: [207, 133, 102]
}

enum ChessPlatform {
    case chessDotCom, lichess
}
