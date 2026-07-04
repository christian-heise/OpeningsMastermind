//
//  LichessStudyStressTests.swift
//  OpeningsMastermindTests
//
//  Stress-tests the PGN decoder against real Lichess studies of varying size and
//  complexity. PGN files live in OpeningsMastermindTests/LichessStudies/ and are
//  accessed via #filePath so they don't need to be in the test bundle.
//
//  To refresh the study corpus run:  Scripts/download_lichess_studies.sh
//

import Testing
import Foundation
@testable import OpeningsMastermind

struct LichessStudyStressTests {

    private let decoder = PGNDecoder()

    // MARK: - Corpus-wide test

    /// Decodes every PGN file in LichessStudies/ and asserts:
    ///   1. No crash, for any study.
    ///   2. No single study takes longer than 60 s to decode.
    ///   3. Each *repertoire* study produces more than the bare root node.
    ///   4. The overall warning rate across repertoire studies stays below 25 %
    ///      of game/chapter count.
    /// "Gamebook"/puzzle-pack studies (every chapter starting from its own
    /// unrelated mid-game FEN) are exempt from 3 and 4 — see
    /// `knownNonRepertoireStudies` below.
    @Test func `All Lichess studies decode`() throws {
        let studiesDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()          // OpeningsMastermindTests/
            .appendingPathComponent("LichessStudies")

        let all = try FileManager.default.contentsOfDirectory(
            at: studiesDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "pgn" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        #expect(!all.isEmpty,
            "No PGN files found at \(studiesDir.path). Run Scripts/download_lichess_studies.sh.")

        // Studies that are intentionally NOT opening repertoires and so don't fit
        // this app's "single tree rooted at the start position" model. Every
        // chapter is a `[SetUp "1"] [ChapterMode "gamebook"]` puzzle starting from
        // its own unrelated mid-game FEN, so the decoder correctly skips every
        // chapter with "setup position is not part of this study". They are still
        // decoded below to exercise the no-crash / bounded-time invariants, but are
        // exempted from the rich-tree and warning-rate checks that only make sense
        // for importable repertoires.
        let knownNonRepertoireStudies: Set<String> = ["9LjyYZ9N"]

        var emptyStudies:   [String] = []
        var slowStudies:    [String] = []
        var totalWarnings   = 0
        var totalChapters   = 0

        for file in all {
            let name = file.deletingPathExtension().lastPathComponent
            let pgn  = try String(contentsOf: file, encoding: .utf8)

            // Rough chapter count: one chapter per [Event] tag.
            let chapters = max(1, pgn.components(separatedBy: "[Event ").count - 1)

            let t0     = Date()
            let result = decoder.decode(pgnString: pgn)
            let elapsed = Date().timeIntervalSince(t0)

            // Report regardless of pass/fail so you can see the breakdown.
            let paddedName = name.padding(toLength: 20, withPad: " ", startingAt: 0)
            print(String(format: "[%@] nodes=%4d  warn=%3d/%3d  %.2fs",
                         paddedName, result.nodes.count,
                         result.warnings.count, chapters, elapsed))
            for w in result.warnings.prefix(5) { print("    ⚠ \(w)") }
            if result.warnings.count > 5 {
                print("    … \(result.warnings.count - 5) more warnings")
            }

            if elapsed > 60 {
                slowStudies.append(String(format: "%@ (%.1fs)", name, elapsed))
            }

            guard !knownNonRepertoireStudies.contains(name) else { continue }

            if result.nodes.count <= 1 {
                emptyStudies.append(name)
            }

            totalWarnings  += result.warnings.count
            totalChapters  += chapters
        }

        #expect(emptyStudies.isEmpty,
            "\("Studies that produced no parseable content:\n  " + emptyStudies.joined(separator: "\n  "))")

        #expect(slowStudies.isEmpty,
            "\("Studies that exceeded 60 s decode time:\n  " + slowStudies.joined(separator: "\n  "))")

        let warningRate = Double(totalWarnings) / Double(max(1, totalChapters))
        #expect(warningRate < 0.25,
            "\(String(format: "Warning rate %.1f%% (%d/%d chapters) is too high.", warningRate * 100, totalWarnings, totalChapters))")
    }

    // MARK: - Individual study spot-checks

    /// The Smith-Morra study used in unit tests must also survive the stress path.
    @Test func `Smith Morra study has rich tree`() throws {
        let file = lichessStudyURL(id: "ccnOaWVC")
        guard let pgn = try? String(contentsOf: file, encoding: .utf8) else {
            try Test.cancel("ccnOaWVC.pgn not found – run Scripts/download_lichess_studies.sh")
        }
        let result = decoder.decode(pgnString: pgn)
        #expect(result.nodes.count > 50,
            "Smith-Morra study should produce a rich tree")
        #expect(result.warnings.isEmpty,
            "Smith-Morra study produced unexpected warnings: \(result.warnings)")
    }

    /// The large Candidates 2026 annotated study pushes the decoder hardest:
    /// ~375 KB, deeply nested variations, clock annotations, arrow markup.
    @Test func `Candidates 2026 study decodes cleanly`() throws {
        let file = lichessStudyURL(id: "Y1yXP80U")
        guard let pgn = try? String(contentsOf: file, encoding: .utf8) else {
            try Test.cancel("Y1yXP80U.pgn not found – run Scripts/download_lichess_studies.sh")
        }
        let result = decoder.decode(pgnString: pgn)
        #expect(result.nodes.count > 100,
            "Candidates 2026 study should produce many nodes")
        // We allow some warnings (unusual PGN from live annotation), but not many.
        let chapters = max(1, pgn.components(separatedBy: "[Event ").count - 1)
        let warningRate = Double(result.warnings.count) / Double(chapters)
        #expect(warningRate < 0.15,
            "Candidates 2026: \(result.warnings.count)/\(chapters) chapters warned – too many")
    }

    /// `GameTree.init` sorts `allGameNodes` by `nodesBelow`. A per-comparison
    /// recursive implementation is effectively O(n² · depth) and "stuck loading"
    /// for minutes on a tree this size; the single `nodesBelowMap` pass must keep
    /// the sort itself near-instant. (Note: `decode` is a separate, slower stage –
    /// this test deliberately gates the sort/map work, not total decode time.)
    @Test func `Candidates 2026 study builds GameTree quickly`() throws {
        let file = lichessStudyURL(id: "Y1yXP80U")
        guard let pgn = try? String(contentsOf: file, encoding: .utf8) else {
            try Test.cancel("Y1yXP80U.pgn not found – run Scripts/download_lichess_studies.sh")
        }

        let decoded = decoder.decode(pgnString: pgn)
        let root = decoded.nodes[0]

        // The nodesBelow pass + sort (the part this fix made non-quadratic) must be
        // near-instant even though the tree has thousands of nodes.
        let tSort0 = Date()
        let map = GameNode.nodesBelowMap(from: root)
        let sorted = GameTree.sortedByNodesBelow(decoded.nodes, from: root)
        let sortElapsed = Date().timeIntervalSince(tSort0)
        #expect(sortElapsed < 1,
            "nodesBelowMap + sort took \(sortElapsed)s for \(decoded.nodes.count) nodes – likely quadratic again")

        #expect(decoded.nodes.count > 100)
        #expect(map.count == decoded.nodes.count)

        // allGameNodes must end up sorted by nodesBelow, descending.
        let values = sorted.map { map[ObjectIdentifier($0)] ?? 0 }
        #expect(values == values.sorted(by: >))
    }

    /// Regression for the deep-line save failure: the Candidates 2026 study has lines
    /// ~170+ plies deep. `DataBase.save()`'s original `JSONEncoder` path failed on it
    /// two ways — a stack overflow on the small main/cooperative-thread stack, and,
    /// once given a large stack, `JSONSerialization`'s 512-level nesting cap
    /// (`Code=3840 "Too many nested arrays or dictionaries"`). The current
    /// `encodeOnLargeStackThread` (binary plist on a 64 MB-stack thread) must handle
    /// both, and `decodeOnLargeStackThread` must round-trip it back to an equivalent
    /// tree — this test only passes because of that combined fix.
    @Test func `Candidates 2026 study saves without stack overflow`() async throws {
        let file = lichessStudyURL(id: "Y1yXP80U")
        guard let pgn = try? String(contentsOf: file, encoding: .utf8) else {
            try Test.cancel("Y1yXP80U.pgn not found – run Scripts/download_lichess_studies.sh")
        }

        let tree = GameTree(name: "Candidates 2026", pgnString: pgn, userColor: .white)
        let db = DataBase(gameTrees: [tree])

        // The encode that overflowed the small stack / hit the JSON nesting cap in `save()`.
        let data = try DataBase.encodeOnLargeStackThread(db)
        #expect(!data.isEmpty)

        // Round-trip on the same large-stack path the loader uses.
        let reloaded = try await DataBase.decodeOnLargeStackThread(from: data)
        #expect(reloaded.gametrees.count == 1)
        #expect(reloaded.gametrees.first?.rootNode.children.map(\.moveString).sorted()
                == tree.rootNode.children.map(\.moveString).sorted())
    }

    /// Legacy `gameTree.json` files were plain JSON; the format sniff in
    /// `decodeOnLargeStackThread` must still read them so upgrading users don't lose
    /// their studies. A shallow tree encoded as JSON must decode back intact.
    @Test func `Legacy JSON database still decodes`() async throws {
        let pgn = "1. e4 e5 2. Nf3 Nc6 3. Bb5 *"
        let tree = GameTree(name: "Ruy Lopez", pgnString: pgn, userColor: .white)
        let db = DataBase(gameTrees: [tree])

        // Simulate an old on-disk file: JSON, not the new binary plist.
        let jsonData = try JSONEncoder().encode(db)
        #expect(!jsonData.starts(with: Array("bplist".utf8)))

        let reloaded = try await DataBase.decodeOnLargeStackThread(from: jsonData)
        #expect(reloaded.gametrees.count == 1)
        #expect(reloaded.gametrees.first?.name == "Ruy Lopez")
        #expect(reloaded.gametrees.first?.rootNode.children.map(\.moveString) == ["e4"])
    }

    /// Regression for the v0.8.x → v0.9 upgrade data loss: `SortingMethod`'s raw value
    /// changed from `String` to `LocalizedStringResource`, so old files store
    /// `"sortSelection": "Manual"` (a string) while the synthesized decoder expected a
    /// dictionary. That `typeMismatch` aborted the whole `DataBase` decode and wiped
    /// every study. A hand-built legacy file with the string form must now decode with
    /// its studies intact.
    @Test func `Legacy string sortSelection does not wipe studies`() async throws {
        let pgn = "1. e4 e5 2. Nf3 Nc6 3. Bb5 *"
        let tree = GameTree(name: "Ruy Lopez", pgnString: pgn, userColor: .white)

        // Encode just the game trees the way the current encoder would…
        let treesData = try JSONEncoder().encode([tree])
        let treesJSON = String(data: treesData, encoding: .utf8)!

        // …then splice them into a hand-built v0.8.x-shaped database: note the
        // string-valued `sortSelection`, exactly as an old build wrote it.
        let legacyJSON = """
        {"appVersion":"0.8.3","sortSelection":"Progress","sortingDirectionIncreasing":false,"gameTrees":\(treesJSON)}
        """
        let data = Data(legacyJSON.utf8)

        let reloaded = try await DataBase.decodeOnLargeStackThread(from: data)
        #expect(reloaded.gametrees.count == 1)
        #expect(reloaded.gametrees.first?.name == "Ruy Lopez")
        #expect(reloaded.sortSelection == .progress)
    }

    /// A freshly-written database must round-trip its sort selection as a plain string
    /// key, so we don't reintroduce the dictionary form that broke old-file loading.
    @Test func `DataBase persists sortSelection as a plain string`() async throws {
        let tree = GameTree(name: "Ruy Lopez", pgnString: "1. e4 *", userColor: .white)
        let db = DataBase(gameTrees: [tree])
        db.sortSelection = .lastPlayed

        let json = String(data: try JSONEncoder().encode(db), encoding: .utf8)!
        #expect(json.contains("\"sortSelection\":\"Last Played\""))

        let reloaded = try await DataBase.decodeOnLargeStackThread(from: Data(json.utf8))
        #expect(reloaded.sortSelection == .lastPlayed)
    }

    /// Regression for the import hang: the Smith-Morra study's graph used to contain
    /// a cycle (a line repeating a position transposed an edge back onto an ancestor),
    /// so `DataBase.save()`'s recursive `JSONEncoder` walk never terminated. The
    /// graph must now be acyclic, so building the tree *and encoding it* both finish.
    @Test func `Smith Morra study builds and encodes without hanging`() throws {
        let file = lichessStudyURL(id: "ccnOaWVC")
        let pgn = try String(contentsOf: file, encoding: .utf8)

        let tree = GameTree(name: "Smith Morra", pgnString: pgn, userColor: .white)
        #expect(tree.allGameNodes.count > 50)

        // This is the call that hung on import. It must complete and round-trip.
        let data = try JSONEncoder().encode(tree)
        #expect(!data.isEmpty)

        let reloaded = try JSONDecoder().decode(GameTree.self, from: data)
        #expect(reloaded.rootNode.children.map(\.moveString).sorted()
                == tree.rootNode.children.map(\.moveString).sorted())
    }

    // MARK: - Edge-case inputs derived from real studies

    /// A comment that contains only a clock annotation must not trip up the
    /// decoder – this pattern is ubiquitous in annotated tournament games.
    @Test func `Clock annotation inside comment`() {
        let pgn = "1. e4 { [%clk 1:59:55] } e5 { [%clk 1:59:43] } 2. Nf3 *"
        let result = decoder.decode(pgnString: pgn)
        #expect(result.warnings == [])
        let root = result.nodes[0]
        #expect(root.children.first != nil, "e4 should be parsed")
        #expect(root.children.first?.child.children.first?.child.children.first?.moveString == "Nf3")
    }

    /// A comment with mixed clock + arrow markup (as in Y1yXP80U) must be
    /// preserved verbatim and not cause a warning.
    @Test func `Mixed clock and arrow annotation`() {
        let pgn = "1. e4 { [%cal Ge4e5][%clk 0:30:00] } *"
        let result = decoder.decode(pgnString: pgn)
        #expect(result.warnings == [])
        #expect(result.nodes[0].children.first?.child.comment == "[%cal Ge4e5][%clk 0:30:00]")
    }

    /// Multi-line pre-game comment (used in the Candidates study to introduce
    /// each round) must not break parsing of the moves that follow.
    @Test func `Pre game comment then moves`() {
        let pgn = """
        [Event "Test"]

        { This is a round introduction.

        It spans multiple lines. }
        1. d4 d5 2. c4 *
        """
        let result = decoder.decode(pgnString: pgn)
        #expect(result.warnings == [])
        let root = result.nodes[0]
        #expect(root.children.first(where: { $0.moveString == "d4" }) != nil)
    }

    // MARK: - Helpers

    private func lichessStudyURL(id: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("LichessStudies")
            .appendingPathComponent("\(id).pgn")
    }
}
