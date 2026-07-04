//
//  ContentView+UITesting.swift
//  OpeningsMastermind
//
//  DEBUG-only hooks that drive the app into the deterministic, content-rich
//  states fastlane `snapshot` captures for App Store screenshots. Everything in
//  here is gated on launch arguments / environment, so it has zero effect on a
//  normal (non-UI-test) launch and is compiled out of Release builds entirely.
//

#if DEBUG
import SwiftUI
import Foundation

/// Launch argument that triggers a clean, pre-seeded state for fastlane
/// `snapshot` UI tests. Kept as a free `let` for source compatibility with the
/// existing `ProcessInfo` checks in `ContentView`.
let uiTestSeedExamplesArgument = UITestSupport.Flag.seedExamples

/// Centralizes every UI-test launch flag and the helpers that act on them.
///
/// The screenshot UI test (`ScreenshotUITests`) launches the app once per
/// scene with a different combination of these flags so that global state
/// (dark mode, board theme) can vary between shots without fragile in-app
/// navigation.
enum UITestSupport {
    enum Flag {
        /// Master switch: wipe persisted state and seed example studies +
        /// practice progress. All other flags are no-ops without it.
        static let seedExamples = "-UITestSeedExamples"
        /// Force dark appearance (the "Learn from your mistakes" practice shot).
        static let darkMode = "-UITestDarkMode"
        /// Auto-open the Practice modal in the "mistake" review state (the
        /// "Learn from your mistakes" shot). Pairs with `darkMode`.
        static let practiceMistake = "-UITestPracticeMistake"
        /// Use the terracotta board theme (the "Customize your board" shot).
        static let terracottaBoard = "-UITestBoardTerracotta"
        /// Pre-fill the Add-Study PGN editor with a sample study (the
        /// "Add custom openings" shot).
        static let prefillPGN = "-UITestPrefillPGN"
    }

    /// The Lichess bearer token to inject so the opening-explorer panel loads
    /// real statistics. Forwarded by the UI test from its own environment,
    /// which xcodebuild populates from a host `TEST_RUNNER_UITEST_LICHESS_TOKEN`
    /// variable — so the token never has to live in the repo.
    static let lichessTokenEnvKey = "UITEST_LICHESS_TOKEN"

    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static func has(_ flag: String) -> Bool { arguments.contains(flag) }

    /// True whenever the app is running under the screenshot UI test.
    static var isActive: Bool { has(Flag.seedExamples) }

    private static var lichessToken: String? {
        guard let token = ProcessInfo.processInfo.environment[lichessTokenEnvKey],
              !token.isEmpty else { return nil }
        return token
    }

    /// A Lichess bearer token to inject on an **ordinary** Debug run — unlike
    /// `lichessTokenEnvKey`, this needs none of the screenshot/seed flags.
    /// Set it in the Xcode scheme (Run → Arguments → Environment Variables) to
    /// launch the simulator already signed in, so explorer-only behaviour that
    /// requires a real token (e.g. the navigation title collapsing while the
    /// Lichess move list scrolls) is reproducible without OAuth in the sim.
    /// The token never lives in the repo; keep it in your local scheme only.
    static let debugLichessTokenEnvKey = "DEBUG_LICHESS_TOKEN"

    private static var debugLichessToken: String? {
        guard let token = ProcessInfo.processInfo.environment[debugLichessTokenEnvKey],
              !token.isEmpty else { return nil }
        return token
    }

    /// `.dark` only for the dark-mode scene, otherwise `nil` (follow the system).
    static var preferredColorScheme: ColorScheme? {
        isActive && has(Flag.darkMode) ? .dark : nil
    }

    /// True for the "Learn from your mistakes" scene: the Practice tab should
    /// auto-present the practice modal already in the `.mistake` review state.
    static var showsPracticeMistake: Bool { isActive && has(Flag.practiceMistake) }

    /// A sample PGN for the Add-Study screenshot, or `nil` when not requested.
    static var prefilledPGN: String? {
        guard isActive, has(Flag.prefillPGN) else { return nil }
        return ExamplePGN.list.first { $0.name == "Smith Morra Gambit" }?.pgnString
    }

    /// The study name to pre-fill alongside `prefilledPGN` so the custom-import
    /// screenshot shows a complete, named study rather than an empty name field.
    static var prefilledStudyName: String? {
        guard isActive, has(Flag.prefillPGN) else { return nil }
        return "Smith Morra Gambit"
    }

    /// When seeding for screenshots, all five example studies are already in the
    /// library, which would dim and disable every row in the Examples tab. This
    /// makes them render as freshly available so the "browse examples" shot
    /// looks inviting instead of greyed-out.
    static var showsExamplesAsAvailable: Bool { isActive }

    // MARK: - Lifecycle hooks

    /// Runs in `ContentView.init` *before* `AppData`/`LichessAuthService` are
    /// constructed: wipes any persisted state from a previous run and injects
    /// the Lichess token into the keychain so `LichessAuthService.init()` reads
    /// it and starts up already signed in.
    static func prepareIfNeeded() {
        guard isActive else { return }
        resetPersistedState()
        if let token = lichessToken {
            injectLichessToken(token)
        }
    }

    /// Runs in `ContentView.init` *before* `LichessAuthService` is constructed:
    /// on a normal Debug launch, injects the `DEBUG_LICHESS_TOKEN` (if set) into
    /// the keychain so the service reads it and starts already signed in. A
    /// no-op under the screenshot UI test (that flow uses `lichessTokenEnvKey`)
    /// and a no-op whenever the env var is absent.
    static func injectDebugLichessTokenIfNeeded() {
        guard !isActive, let token = debugLichessToken else { return }
        injectLichessToken(token)
    }

    /// Runs in `ContentView.init` right after `AppData` is built, applying
    /// settings overrides that must be in place before the first render.
    @MainActor
    static func applySettings(to appData: AppData) {
        guard isActive else { return }
        // Suppress the one-time "What's New" splash so it can't cover the
        // Explorer board or block tab navigation during screenshot capture.
        appData.settings.lastSeenWhatsNewVersion = WhatsNewView.appVersion
        if has(Flag.terracottaBoard) {
            appData.settings.boardColorRGB.black = [207, 133, 102] // terracotta
        }
    }

    /// Runs from `ContentView`'s `onAppear`: seeds the five example studies and
    /// fakes some practice history so the Library/Practice screens look used.
    @MainActor
    static func seed(into database: DataBase) {
        guard isActive, database.gametrees.isEmpty else { return }
        Task {
            for example in ExamplePGN.list {
                guard let pgnString = example.pgnString else { continue }
                _ = await database.addNewGameTree(
                    name: example.name,
                    pgnString: pgnString,
                    userColor: example.userColor
                )
            }
            await MainActor.run { seedProgress(in: database) }
        }
    }

    // MARK: - Implementation

    private static func resetPersistedState() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for filename in ["gameTree.json", "settings.json"] {
            try? FileManager.default.removeItem(at: documents.appendingPathComponent(filename))
        }
    }

    private static func injectLichessToken(_ token: String) {
        let keychain = KeychainStore(
            service: Bundle.main.bundleIdentifier ?? "OpeningsMastermind",
            account: "lichess-oauth-token"
        )
        keychain.save(token)
    }

    /// Marks a per-study fraction of nodes as "answered correctly" so each
    /// study shows a distinct, non-zero progress bar (mirroring the spread of
    /// the original App Store screenshots), and seeds a couple of due review
    /// nodes per study so the Practice "Up next" queue shows recognizable
    /// mid-line positions instead of the starting position.
    @MainActor
    private static func seedProgress(in database: DataBase) {
        let fractionByName: [String: Double] = [
            "Danish Gambit Refutation": 0.08,
            "Scotch Gambit": 0.06,
            "Caro Kann Goldman Variation": 0.22,
            "Englund Gambit Refutation": 0.76,
            "Smith Morra Gambit": 0.86,
        ]
        let today = Date()
        // Answered correctly a few days ago: past its one-day review interval,
        // so `dueDate <= now` and the node resurfaces in the practice queue.
        let dueTry = today.addingTimeInterval(-3 * 24 * 60 * 60)

        for tree in database.gametrees {
            let fraction = fractionByName[tree.name] ?? 0.3
            // `allGameNodes` is sorted by `nodesBelow` (root first); skip the
            // root and mark the leading fraction as answered correctly *today*.
            // Today's answer isn't due yet, so these only drive the progress
            // bars — they stay out of the "Up next" queue.
            let nodes = tree.allGameNodes.dropFirst()
            let masteredCount = Int((Double(nodes.count) * fraction).rounded())
            for node in nodes.prefix(masteredCount) {
                node.mistakesLast5Moves[today] = false // false == not a mistake
            }

            // Pick a couple of user-to-move nodes a few plies into the line and
            // mark them answered-correctly-but-now-due. `getQueueItems` surfaces
            // exactly these (no other node is due), so the queue shows real
            // mid-game positions. `nodes` is already nodesBelow-descending, so
            // `prefix(2)` favours the most central (main-line) candidates.
            let queueCandidates = nodes.filter {
                $0.nextMoveColor == tree.userColor && !$0.children.isEmpty
            }
            let deepEnough = queueCandidates.filter {
                ($0.parents.first?.halfMoveNumber ?? 0) >= 6
            }
            let chosen = (deepEnough.isEmpty ? queueCandidates : deepEnough).prefix(2)
            for node in chosen {
                node.mistakesLast5Moves = [dueTry: false] // overwrite → due now
            }
        }
        database.objectWillChange.send()
    }
}
#endif
