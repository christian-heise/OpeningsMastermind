//
//  AnalyticsService.swift
//  OpeningsMastermind
//

import Foundation
import TelemetryDeck

/// Applies the analytics privacy toggle to TelemetryDeck and
/// `CrashReporter`. Called at launch and whenever the toggle changes in
/// `SettingsViewModel`, so the change takes effect immediately without
/// restarting the app. Crash diagnostics are forwarded to TelemetryDeck, so
/// they're gated by the same toggle as analytics.
enum AnalyticsService {
    static func configure(analyticsEnabled: Bool) {
        if analyticsEnabled,
           let appId = Bundle.main.infoDictionary?["TelemetryDeckAppId"] as? String, !appId.isEmpty {
            let config = TelemetryDeck.Config(appID: appId)
            TelemetryDeck.initialize(config: config)
            CrashReporter.start()
        } else if TelemetryManager.isInitialized {
            TelemetryDeck.terminate()
            CrashReporter.stop()
        }
    }
}
