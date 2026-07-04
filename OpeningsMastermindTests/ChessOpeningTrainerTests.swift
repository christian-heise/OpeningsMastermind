//
//  ChessOpeningTrainerTests.swift
//  ChessOpeningTrainerTests
//
//  Created by Christian Gleißner on 19.04.23.
//

import Testing
import Foundation
@testable import OpeningsMastermind

struct PGNDecoderTests {

    private let decoder = PGNDecoder()

    // MARK: - Helpers

    /// Decodes a PGN, returning the root node and any warnings.
    private func decode(_ pgn: String) -> (root: GameNode, nodes: [GameNode], warnings: [String]) {
        let result = decoder.decode(pgnString: pgn)
        return (result.nodes[0], result.nodes, result.warnings)
    }

    /// Walks the main line (first child at each step) and returns the moveStrings.
    private func mainLine(from node: GameNode) -> [String] {
        var moves: [String] = []
        var current = node
        while let next = current.children.first {
            moves.append(next.moveString)
            current = next.child
        }
        return moves
    }

    /// Finds the child reached by the given move from a node.
    private func child(_ node: GameNode, _ moveString: String) -> GameNode? {
        node.children.first(where: { $0.moveString == moveString })?.child
    }

    // MARK: - Basic parsing

    @Test func `Linear game`() {
        let (root, _, warnings) = decode("1. e4 e5 2. Nf3 Nc6 3. Bb5 *")
        #expect(warnings.isEmpty)
        #expect(mainLine(from: root) == ["e4", "e5", "Nf3", "Nc6", "Bb5"])
    }

    /// Movetext that wraps over several lines used to reset the old decoder.
    @Test func `Multi line movetext`() {
        let pgn = """
        1. e4 e5
        2. Nf3 Nc6
        3. Bb5 a6
        4. Ba4 Nf6 *
        """
        let (root, _, warnings) = decode(pgn)
        #expect(warnings.isEmpty)
        #expect(mainLine(from: root) == ["e4", "e5", "Nf3", "Nc6", "Bb5", "a6", "Ba4", "Nf6"])
    }

    /// Move numbers glued to moves, e.g. "1.e4", must still parse.
    @Test func `Glued move numbers`() {
        let (root, _, _) = decode("1.e4 e5 2.Nf3 Nc6 *")
        #expect(mainLine(from: root) == ["e4", "e5", "Nf3", "Nc6"])
    }

    @Test func `Canonical check and mate symbols`() {
        // Scholar's mate – the final move should keep its '#'.
        let (root, _, _) = decode("1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# *")
        #expect(mainLine(from: root).last == "Qxf7#")
    }

    @Test func `En passant canonical form`() {
        let (root, _, _) = decode("1. e4 d5 2. e5 f5 3. exf6 *")
        #expect(mainLine(from: root) == ["e4", "d5", "e5", "f5", "exf6"])
    }

    @Test func castling() {
        // Both sides develop the kingside knight before castling short.
        let (root, _, warnings) = decode("1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O Nf6 5. d3 O-O *")
        #expect(warnings.isEmpty, "warnings: \(warnings)")
        #expect(mainLine(from: root) ==
                ["e4", "e5", "Nf3", "Nc6", "Bc4", "Bc5", "O-O", "Nf6", "d3", "O-O"])
    }

    @Test func `Queenside castling with zeros`() {
        // Some sources spell castling with zeros (0-0-0).
        let pgn = "1. d4 d5 2. Nc3 Nc6 3. Bf4 Bf5 4. Qd2 Qd7 5. 0-0-0 0-0-0 *"
        let (root, _, warnings) = decode(pgn)
        #expect(warnings.isEmpty)
        #expect(mainLine(from: root).suffix(2) == ["O-O-O", "O-O-O"])
    }

    @Test func promotion() {
        // 1.e4 d5 2.exd5 c6 3.dxc6 Qb6 4.cxb7 Qc7 5.bxa8=Q
        let pgn = "1. e4 d5 2. exd5 c6 3. dxc6 Qb6 4. cxb7 Qc7 5. bxa8=Q *"
        let (root, _, warnings) = decode(pgn)
        #expect(warnings.isEmpty, "warnings: \(warnings)")
        #expect(mainLine(from: root).last == "bxa8=Q")
    }

    /// A source over-disambiguating a move ("Ngf3" where only one knight can
    /// reach f3) must still resolve, and be stored canonically as "Nf3".
    @Test func `Over disambiguated move`() {
        let (root, _, warnings) = decode("1. Ngf3 *")
        #expect(warnings.isEmpty)
        #expect(root.children.first?.moveString == "Nf3")
    }

    // MARK: - Comments, NAGs, annotations

    @Test func `Comments attach to node`() {
        let pgn = "1. e4 { King's pawn } e5 2. Nf3 { develops } *"
        let (root, _, _) = decode(pgn)
        let e4 = child(root, "e4")
        #expect(e4?.comment == "King's pawn")
        #expect(child(e4!, "e5").flatMap { child($0, "Nf3") }?.comment == "develops")
    }

    @Test func `Lichess arrow annotations preserved in comment`() {
        let pgn = "1. e4 { [%cal Re4e5][%csl Gd4] } *"
        let (root, _, _) = decode(pgn)
        #expect(child(root, "e4")?.comment == "[%cal Re4e5][%csl Gd4]")
    }

    @Test func `Multiple comments concatenated`() {
        let pgn = "1. e4 { first } { second } *"
        let (root, _, _) = decode(pgn)
        #expect(child(root, "e4")?.comment == "first\n\nsecond")
    }

    @Test func `Semicolon comment`() {
        let pgn = "1. e4 ; rest of line comment\n e5 *"
        let (root, _, _) = decode(pgn)
        #expect(child(root, "e4")?.comment == "rest of line comment")
        #expect(child(root, "e4").flatMap { child($0, "e5") } != nil)
    }

    @Test func `NAGs are ignored gracefully`() {
        let pgn = "1. e4 $1 e5 $146 2. Nf3 $18 *"
        let (root, _, warnings) = decode(pgn)
        #expect(warnings.isEmpty)
        #expect(mainLine(from: root) == ["e4", "e5", "Nf3"])
    }

    @Test func `Move annotation glyphs stored`() {
        let pgn = "1. e4 e5 2. Nf3?! Nc6!? *"
        let (root, _, _) = decode(pgn)
        let nf3 = child(root, "e4").flatMap { child($0, "e5") }?.children.first
        #expect(nf3?.moveString == "Nf3")
        #expect(nf3?.annotation == "?!")
    }

    // MARK: - Variations (RAV)

    @Test func `Simple variation`() {
        // 1. e4 e5 (1... c5) 2. Nf3
        let pgn = "1. e4 e5 (1... c5) 2. Nf3 *"
        let (root, _, warnings) = decode(pgn)
        #expect(warnings.isEmpty)
        let e4 = child(root, "e4")
        #expect(Set(e4!.children.map { $0.moveString }) == ["e5", "c5"])
        // Mainline continues after the variation.
        #expect(child(e4!, "e5").flatMap { child($0, "Nf3") } != nil)
    }

    @Test func `Nested variations`() {
        let pgn = "1. e4 c5 2. Nf3 (2. Nc3 Nc6 (2... d6 3. f4)) 2... d6 *"
        let (root, _, warnings) = decode(pgn)
        #expect(warnings.isEmpty)
        let afterC5 = child(root, "e4").flatMap { child($0, "c5") }
        #expect(Set(afterC5!.children.map { $0.moveString }) == ["Nf3", "Nc3"])
        let nc3 = child(afterC5!, "Nc3")
        #expect(Set(nc3!.children.map { $0.moveString }) == ["Nc6", "d6"])
        // The deepest nested line 2...d6 3.f4 exists.
        #expect(child(nc3!, "d6").flatMap { child($0, "f4") } != nil)
        // Mainline 2...d6 continues from the real Nf3 node.
        #expect(child(afterC5!, "Nf3").flatMap { child($0, "d6") } != nil)
    }

    // MARK: - Transpositions / multiple games

    @Test func `Transposition shares node`() {
        // Two games reaching the same position via different move orders.
        let pgn = """
        [Event "A"]

        1. e4 e5 2. Nf3 *

        [Event "B"]

        1. Nf3 e5 2. e4 *
        """
        let (root, nodes, _) = decode(pgn)
        let viaE4 = child(root, "e4").flatMap { child($0, "e5") }.flatMap { child($0, "Nf3") }
        let viaNf3 = child(root, "Nf3").flatMap { child($0, "e5") }.flatMap { child($0, "e4") }
        #expect(viaE4 != nil)
        #expect(viaE4 === viaNf3, "Transposing move orders should share one GameNode")
        // root, e4, e4e5, shared, Nf3, Nf3e5  => 6 unique nodes
        #expect(nodes.count == 6)
    }

    /// A line that *repeats* a position (here returning to the start position after
    /// 2. Ng1 Ng8) must NOT loop an edge back onto its own ancestor: the repeated
    /// position is reached at a higher move number and is a distinct game state
    /// (advancing toward a threefold draw). Folding the full-move number into the
    /// transposition key keeps the graph acyclic, so every tree walker terminates.
    @Test func `Repetition in a line does not create a cycle`() {
        let (root, nodes, _) = decode("1. Nf3 Nf6 2. Ng1 Ng8 *")

        let afterNg8 = child(root, "Nf3").flatMap { child($0, "Nf6") }
            .flatMap { child($0, "Ng1") }.flatMap { child($0, "Ng8") }
        #expect(afterNg8 != nil)
        #expect(afterNg8 !== root, "A repeated position must be its own node, not a back-edge to the root")
        // root + Nf3 + Nf6 + Ng1 + Ng8 => 5 distinct nodes (no transposition merge).
        #expect(nodes.count == 5)

        // The graph is acyclic, so all the recursive properties terminate.
        #expect(root.nodesBelow == 4)
        #expect(root.mistakesRate >= 0)
        #expect(root.depth == 4)
        #expect(root.progress.isFinite)
    }

    // MARK: - Error handling / robustness

    @Test func `Illegal move is skipped not crashed`() {
        // "Qh6" is illegal on move 2; the game is skipped after it, but the
        // legal prefix is still parsed and a warning is recorded.
        let (root, _, warnings) = decode("1. e4 Qh6 2. Nf3 *")
        #expect(mainLine(from: root) == ["e4"])
        #expect(!warnings.isEmpty)
    }

    @Test func `Garbage move is skipped`() {
        let (root, _, warnings) = decode("1. e4 zz9 *")
        #expect(mainLine(from: root) == ["e4"])
        #expect(!warnings.isEmpty)
    }

    @Test func `One bad game does not kill others`() {
        let pgn = """
        [Event "Broken"]

        1. e4 Qh6 *

        [Event "Good"]

        1. d4 d5 2. c4 *
        """
        let (root, _, warnings) = decode(pgn)
        // The good game's moves are present.
        #expect(child(root, "d4").flatMap { child($0, "d5") }.flatMap { child($0, "c4") } != nil)
        #expect(!warnings.isEmpty)
    }

    @Test func `Empty PGN throws`() {
        #expect(throws: PGNDecodingError.emptyPGN) {
            try decoder.decodePGN(pgnString: "   \n  ")
        }
    }

    @Test func `No parsable games throws`() {
        #expect(throws: PGNDecodingError.noGamesParsed) {
            try decoder.decodePGN(pgnString: "[Event \"x\"]\n\n zz9 qq8 *")
        }
    }

    @Test func `Incompatible FEN setup skipped with warning`() {
        let pgn = """
        [SetUp "1"]
        [FEN "rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq - 1 1"]

        1... d5 *
        """
        let (root, _, warnings) = decode(pgn)
        #expect(root.children.isEmpty, "An unreachable setup position should be skipped")
        #expect(!warnings.isEmpty)
    }

    @Test func `Unbalanced parentheses reported`() {
        let (_, _, warnings) = decode("1. e4 e5 (2. Nf3 *")
        #expect(!warnings.isEmpty)
    }

    // MARK: - Realistic study excerpt (regression)

    /// A trimmed but real excerpt of a Lichess study chapter, exercising
    /// nested variations, NAGs, promotions, multi-block comments with arrow
    /// annotations, glyph annotations and castling all at once.
    @Test func `Realistic study excerpt parses`() {
        let pgn = #"""
        [Event "Smith-Morra Gambit: An Overview"]
        [Site "https://lichess.org/study/ccnOaWVC/dTyYqiHr"]
        [Result "*"]
        [Variant "Standard"]
        [ECO "B21"]

        1. e4 c5 2. d4!? { d4 defines the gambit. } 2... cxd4 3. c3! { The key move. }
        (3. Qxd4?! Nc6 4. Qe3 Nf6 { Black scores well here. })
        (3. Nf3!? e5 4. Nxe5?? Qa5+ { [%cal Ga5e5,Ga5e1] })
        3... dxc3 (3... Nf6 { Transposes to the Alapin. })
        4. Nxc3 Nc6 { [%cal Gg1f3,Gf1c4,Ge1g1] } 5. Nf3 d6 6. Bc4 e6 7. O-O Be7 $146 *
        """#
        let result = decoder.decode(pgnString: pgn)
        let root = result.nodes[0]
        #expect(result.warnings.isEmpty, "warnings: \(result.warnings)")

        // Main line down to 7...Be7.
        #expect(mainLine(from: root) ==
                ["e4", "c5", "d4", "cxd4", "c3", "dxc3", "Nxc3", "Nc6",
                 "Nf3", "d6", "Bc4", "e6", "O-O", "Be7"])

        // Annotation glyph on d4 preserved.
        let d4 = child(root, "e4").flatMap { child($0, "c5") }?.children.first
        #expect(d4?.annotation == "!?")

        // Variation 3. Qxd4 branches from the position before 3. c3.
        let beforeMove3 = child(root, "e4").flatMap { child($0, "c5") }
            .flatMap { child($0, "d4") }.flatMap { child($0, "cxd4") }
        #expect(Set(beforeMove3!.children.map { $0.moveString }) == ["c3", "Qxd4", "Nf3"])
    }

    /// Decodes every full-length PGN shipped with the app and asserts each
    /// yields a non-trivial tree without crashing. The files are loaded from the
    /// app's `Data` directory (located relative to this test's source file),
    /// since they are members of the app target rather than the test bundle.
    @Test func `Shipped example PGNs parse`() throws {
        let names = ["exampleCaroKannGoldman", "exampleDanishRefutation",
                     "exampleScotchGambit", "exampleSmithMorra", "exampleEnglundRefutation"]

        // .../OpeningsMastermindTests/ChessOpeningTrainerTests.swift -> repo root
        let dataDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // OpeningsMastermindTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("OpeningsMastermind/Data")

        var tested = 0
        for name in names {
            let url = dataDir.appendingPathComponent(name).appendingPathExtension("pgn")
            guard let pgn = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }
            tested += 1
            let result = decoder.decode(pgnString: pgn)
            #expect(result.nodes.count > 10, "\(name) produced too few nodes")
            #expect(!result.nodes[0].children.isEmpty, "\(name) produced an empty tree")
            #expect(result.warnings.isEmpty,
                    "\(name) produced warnings: \(result.warnings)")
        }
        #expect(tested > 0, "Could not locate any shipped example PGNs at \(dataDir.path)")
    }
}
