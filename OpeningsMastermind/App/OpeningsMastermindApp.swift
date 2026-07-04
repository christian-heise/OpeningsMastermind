//
//  ChessOpeningTrainerApp.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.04.23.
//

import SwiftUI

@main
struct OpeningsMastermindApp: App {
    init() {
        // ChessKitEngine's EngineMessenger writes UCI commands to the engine via a
        // raw `write()` on a pipe (see EngineMessenger.sendCommand:), with no SIGPIPE
        // guard and no synchronization against its own `stop` closing that pipe. Any
        // command that lands after the pipe's read end is gone raises SIGPIPE, whose
        // default disposition terminates the whole app with "signal 13" and no crash
        // log. Ignore it process-wide so the stray write fails with EPIPE instead.
        signal(SIGPIPE, SIG_IGN)

        let settings = AppData.load() ?? SettingsData()
        AnalyticsService.configure(analyticsEnabled: settings.analyticsEnabled)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
