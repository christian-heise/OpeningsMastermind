//
//  ScreenshotUITests.swift
//  OpeningsMastermindUITests
//
//  Drives the app for fastlane `snapshot` App Store screenshots. Every scene
//  launches with `-UITestSeedExamples` (appended by the Snapfile via
//  `setupSnapshot`), which makes the app reset its persisted state, seed the
//  bundled example studies, and fake some practice progress — see
//  `UITestSupport` (App/ContentView+UITesting.swift) — so the screenshots show
//  real opening content instead of empty-state placeholders.
//
//  Scenes whose *global* state differs (dark mode, board theme) live in their
//  own test method, since that can only be set at launch. The remaining scenes
//  share one launch and are reached by navigation.
//

import XCTest
import UIKit

final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Scenes sharing one (light-mode) launch

    @MainActor
    func testMainScenes() throws {
        let app = makeApp(extraArguments: ["-UITestPrefillPGN"])
        app.launch()
        orientForIdiom()

        let tabs = TabBar(app: app)

        // 1) Explorer — a recognizable mid-line position with the Lichess
        //    opening stats + move list populated, not the starting position.
        tabs.explorer.tap()
        selectStudy(named: "Smith Morra Gambit", in: app)
        advanceExplorer(plies: 11, in: app)
        // Give the Lichess opening-explorer request time to return over the network.
        sleep(4)
        snapshot("01Explorer")

        // 2) Library — the study list with progress bars.
        tabs.library.tap()
        snapshot("02Library")

        // 3) Add Study — the custom-PGN import tab (editor pre-filled). This is
        //    the default tab, so no interaction is needed before the shot.
        app.buttons["library.addStudyButton"].firstMatch.tap()
        // Wait on the close button's identifier, not the navigation title — the
        // title is localized ("Add Study" / "Studie hinzufügen"), so asserting
        // on the English literal aborts the whole test in the de-DE run.
        XCTAssertTrue(app.buttons["addStudy.closeButton"].waitForExistence(timeout: 5))
        snapshot("03AddStudyCustom")

        // 4) Add Study — the bundled example-studies tab. The import selector is
        //    the *second* segmented control on screen (the first is the
        //    white/black color picker); its identifier doesn't reliably reach
        //    the XCUIElement, so address it by position.
        let importPicker = app.segmentedControls["addStudy.importPicker"].exists
            ? app.segmentedControls["addStudy.importPicker"]
            : app.segmentedControls.element(boundBy: 1)
        importPicker.buttons.element(boundBy: 1).tap() // Examples
        snapshot("04AddStudyExamples")
        app.buttons["addStudy.closeButton"].firstMatch.tap()

        // 5) Practice — the "Up next" smart training queue.
        tabs.practice.tap()
        snapshot("05Practice")
    }

    // MARK: - Scenes needing a dedicated launch state

    @MainActor
    func testCustomizeBoardScene() throws {
        let app = makeApp(extraArguments: ["-UITestBoardTerracotta"])
        app.launch()
        orientForIdiom()

        let tabs = TabBar(app: app)
        tabs.explorer.tap()
        selectStudy(named: "Smith Morra Gambit", in: app)
        advanceExplorer(plies: 6, in: app)
        sleep(4)
        snapshot("06CustomizeBoard")
    }

    /// The dark-mode "Learn from your mistakes" shot: the app auto-presents the
    /// Practice modal already in the mistake review state (correction arrow +
    /// "not in your studies" banner), so no fragile board drag is needed. Both
    /// the dark appearance and the auto-present are launch-global, hence a
    /// dedicated launch.
    @MainActor
    func testPracticeMistakeScene() throws {
        let app = makeApp(extraArguments: ["-UITestDarkMode", "-UITestPracticeMistake"])
        app.launch()
        orientForIdiom()

        TabBar(app: app).practice.tap()
        // Wait on a locale-independent accessibility identifier (the banner text
        // is localized) — the modal only presents once the seeded study loads.
        XCTAssertTrue(app.buttons["practice.reviewInExplorerButton"].waitForExistence(timeout: 30))
        snapshot("07PracticeMistake")
    }

    // MARK: - Helpers

    /// The app is landscape-optimized on iPad, so capture iPad shots in
    /// landscape (matching the landscape device frame frameit/`frame_ipad.sh`
    /// applies). iPhone scenes stay portrait. Call right after `app.launch()`.
    @MainActor
    private func orientForIdiom() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    @MainActor
    private func makeApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += extraArguments
        // Forward the Lichess token (set on the host as
        // TEST_RUNNER_UITEST_LICHESS_TOKEN) so the explorer stats panel loads.
        if let token = ProcessInfo.processInfo.environment["UITEST_LICHESS_TOKEN"] {
            app.launchEnvironment["UITEST_LICHESS_TOKEN"] = token
        }
        return app
    }

    /// Opens the switch-study sheet and selects the named study. Waits for the
    /// button to become *enabled* — it stays disabled until the example studies
    /// finish seeding asynchronously at launch.
    @MainActor
    private func selectStudy(named name: String, in app: XCUIApplication) {
        let switchStudyButton = app.buttons["explorer.switchStudyButton"]
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: switchStudyButton)
        waitForExpectations(timeout: 30)
        switchStudyButton.tap()
        let row = app.buttons[name]
        if row.waitForExistence(timeout: 10) {
            row.tap()
        }
    }

    /// Steps the explorer forward along the main line to reach a deeper position.
    @MainActor
    private func advanceExplorer(plies: Int, in app: XCUIApplication) {
        let forward = app.buttons["explorer.forwardButton"]
        guard forward.waitForExistence(timeout: 10) else { return }
        for _ in 0..<plies where forward.isEnabled {
            forward.tap()
        }
    }
}

/// The four bottom tabs, addressed by position on the native iPhone `UITabBar`
/// (whose buttons don't reliably carry the `.accessibilityIdentifier` set on
/// the `Label` inside `.tabItem`) and by identifier on iPad's adaptive sidebar.
/// The tab order (Explorer, Practice, Library, Settings) is fixed in ContentView.
@MainActor
private struct TabBar {
    let app: XCUIApplication
    private let usesNativeTabBar: Bool

    init(app: XCUIApplication) {
        self.app = app
        self.usesNativeTabBar = app.tabBars.firstMatch.waitForExistence(timeout: 10)
    }

    private func tab(_ identifier: String, index: Int) -> XCUIElement {
        usesNativeTabBar
            ? app.tabBars.firstMatch.buttons.element(boundBy: index)
            : app.buttons[identifier].firstMatch
    }

    var explorer: XCUIElement { tab("tab.explorer", index: 0) }
    var practice: XCUIElement { tab("tab.practice", index: 1) }
    var library: XCUIElement { tab("tab.library", index: 2) }
    var settings: XCUIElement { tab("tab.settings", index: 3) }
}
