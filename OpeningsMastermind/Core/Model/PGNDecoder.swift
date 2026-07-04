//
//  PGNDecoder.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 12.06.23.
//

import Foundation
import ChessKit

/// Errors that can occur while decoding a PGN. These are recoverable on a
/// per-game basis: a single malformed game is skipped and reported as a
/// warning rather than aborting the whole import.
enum PGNDecodingError: LocalizedError, Equatable {
    /// The input contained no movetext at all.
    case emptyPGN
    /// Not a single game could be parsed from the input.
    case noGamesParsed
    /// A move could not be matched to any legal move in the given position.
    case illegalMove(san: String, fen: String)
    /// A move matched more than one legal move (insufficient disambiguation).
    case ambiguousMove(san: String, fen: String)
    /// A move token did not look like valid SAN.
    case malformedSAN(String)
    /// A game used a `FEN` setup position that does not occur in the tree.
    case incompatibleSetupPosition(fen: String)

    var errorDescription: String? {
        switch self {
        case .emptyPGN:
            return "The PGN did not contain any moves."
        case .noGamesParsed:
            return "None of the games in the PGN could be read."
        case .illegalMove(let san, _):
            return "Illegal or unrecognized move “\(san)”."
        case .ambiguousMove(let san, _):
            return "The move “\(san)” is ambiguous in its position."
        case .malformedSAN(let san):
            return "“\(san)” is not a valid move."
        case .incompatibleSetupPosition:
            return "A chapter starts from a position that is not part of this study."
        }
    }
}

/// The result of decoding a PGN string.
struct PGNDecodeResult {
    /// All unique positions, with the standard start position first.
    let nodes: [GameNode]
    /// Human readable, non-fatal problems encountered while parsing.
    let warnings: [String]
}

/// Decodes a PGN string into a graph of `GameNode`/`MoveNode` objects.
///
/// The decoder is implemented as a tokenizer followed by a parser. Transposing
/// move orders that reach the same position share a single `GameNode`; multiple
/// games (e.g. the chapters of a Lichess study) are merged into one tree rooted
/// at the standard starting position.
class PGNDecoder {
    static let `default` = PGNDecoder()

    /// Parsing progress in `0...1`, useful for a progress indicator.
    var progress: Double = 0.0

    /// Warnings collected during the most recent decode call.
    private(set) var lastWarnings: [String] = []

    // MARK: - Public API

    /// Decodes the given PGN, throwing only if nothing at all could be parsed.
    ///
    /// On partial success the successfully parsed nodes are returned and the
    /// skipped games are available in `lastWarnings`.
    func decodePGN(pgnString: String) throws -> [GameNode] {
        let result = decode(pgnString: pgnString)
        lastWarnings = result.warnings

        // `nodes` always contains at least the root. If nothing beyond the root
        // was produced, the import failed.
        if result.nodes.count <= 1 {
            if pgnString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw PGNDecodingError.emptyPGN
            }
            throw PGNDecodingError.noGamesParsed
        }
        return result.nodes
    }

    /// Decodes the given PGN. Never throws; on total failure it returns just the
    /// root node together with the collected warnings.
    func decode(pgnString: String) -> PGNDecodeResult {
        progress = 0.0
        let tokens = tokenize(pgnString)
        let parser = Parser(tokens: tokens) { [weak self] fraction in
            self?.progress = fraction
        }
        let result = parser.run()
        progress = 1.0
        lastWarnings = result.warnings
        return result
    }

    // MARK: - Tokenizer

    /// A lexical token of a PGN file.
    enum Token: Equatable {
        case tagPair(key: String, value: String)
        case move(String)            // SAN, possibly with annotation glyphs
        case nag(String)             // numeric annotation glyph, e.g. "$1"
        case comment(String)
        case variationStart
        case variationEnd
        case termination(String)     // "1-0", "0-1", "1/2-1/2", "*"
    }

    /// Splits a PGN string into tokens. This handles tag pairs with escaped
    /// quotes, brace comments, rest-of-line (`;`) comments, NAGs, variations,
    /// game termination markers and move numbers glued to moves (e.g. `1.e4`).
    func tokenize(_ pgn: String) -> [Token] {
        var tokens: [Token] = []
        let chars = Array(pgn)
        var i = 0
        let n = chars.count

        func peek() -> Character? { i < n ? chars[i] : nil }

        while i < n {
            let c = chars[i]
            switch c {
            case "[":
                i += 1
                tokenizeTagPair(chars, &i, into: &tokens)
            case "{":
                i += 1
                var text = ""
                while i < n && chars[i] != "}" {
                    text.append(chars[i]); i += 1
                }
                if i < n { i += 1 } // consume "}"
                tokens.append(.comment(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            case ";":
                i += 1
                var text = ""
                while i < n && chars[i] != "\n" {
                    text.append(chars[i]); i += 1
                }
                tokens.append(.comment(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            case "(":
                tokens.append(.variationStart); i += 1
            case ")":
                tokens.append(.variationEnd); i += 1
            case "$":
                i += 1
                var nag = "$"
                while i < n, chars[i].isNumber {
                    nag.append(chars[i]); i += 1
                }
                tokens.append(.nag(nag))
            case "*":
                tokens.append(.termination("*")); i += 1
            case let ch where ch.isWhitespace:
                i += 1
            default:
                // Read a whitespace/structure-delimited word and classify it.
                var word = ""
                while i < n {
                    let ch = chars[i]
                    if ch.isWhitespace || ch == "{" || ch == "}" || ch == "("
                        || ch == ")" || ch == ";" || ch == "$" {
                        break
                    }
                    word.append(ch); i += 1
                }
                classifyWord(word, into: &tokens)
            }
            _ = peek()
        }
        return tokens
    }

    private func tokenizeTagPair(_ chars: [Character], _ i: inout Int, into tokens: inout [Token]) {
        let n = chars.count
        var key = ""
        // Read the key up to the opening quote.
        while i < n, chars[i] != "\"", chars[i] != "]" {
            key.append(chars[i]); i += 1
        }
        var value = ""
        if i < n, chars[i] == "\"" {
            i += 1 // consume opening quote
            var escaped = false
            while i < n {
                let ch = chars[i]
                if escaped {
                    value.append(ch); escaped = false; i += 1
                } else if ch == "\\" {
                    escaped = true; i += 1
                } else if ch == "\"" {
                    i += 1; break
                } else {
                    value.append(ch); i += 1
                }
            }
        }
        // Consume up to and including the closing bracket.
        while i < n, chars[i] != "]" { i += 1 }
        if i < n { i += 1 } // consume "]"
        tokens.append(.tagPair(key: key.trimmingCharacters(in: .whitespaces), value: value))
    }

    /// Classifies a raw movetext word into zero or more tokens. A word may be a
    /// move number (`12.`), a move number glued to a move (`12.e4`, `12...Nf6`),
    /// a termination marker, or a SAN move.
    private func classifyWord(_ word: String, into tokens: inout [Token]) {
        if word.isEmpty { return }

        let terminations: Set<String> = ["1-0", "0-1", "1/2-1/2"]
        if terminations.contains(word) {
            tokens.append(.termination(word)); return
        }

        // Strip a leading move-number indicator such as "12." or "12...".
        var rest = word
        if let range = rest.range(of: #"^\d+\.(\.\.)?"#, options: .regularExpression) {
            rest.removeSubrange(range)
        }
        if rest.isEmpty { return }                      // pure move number
        if rest.allSatisfy({ $0.isNumber }) { return }  // stray number, not SAN
        if terminations.contains(rest) {
            tokens.append(.termination(rest)); return
        }
        tokens.append(.move(rest))
    }

    // MARK: - Parser

    /// Builds the position graph from a token stream.
    private final class Parser {
        private let tokens: [PGNDecoder.Token]
        private let onProgress: (Double) -> Void

        // Shared tree state.
        private let rootNode = GameNode(fen: startingFEN)
        private var allNodes: [GameNode]
        private var dictNode: [Position: GameNode]
        private var dictBoardNode: [Board: GameNode]
        private var warnings: [String] = []

        // Per-game state.
        private var currentNode: GameNode
        private var game = Game(position: startingGamePosition)
        private var startNode: GameNode
        /// Branch point for the next `(`: the position *before* the last move.
        private var branchNode: GameNode?
        private var branchGame: Game?
        private var variationStack: [LineState] = []
        private var inMovetext = false
        private var gameFailed = false
        private var gameSkipped = false
        private var pendingTags: [String: String] = [:]
        private var gameIndex = 0

        private struct LineState {
            let node: GameNode
            let game: Game
            let branchNode: GameNode?
            let branchGame: Game?
        }

        init(tokens: [PGNDecoder.Token], onProgress: @escaping (Double) -> Void) {
            self.tokens = tokens
            self.onProgress = onProgress
            self.allNodes = [rootNode]
            self.dictNode = [Parser.positionKey(startingGamePosition): rootNode]
            self.dictBoardNode = [startingGamePosition.board: rootNode]
            self.currentNode = rootNode
            self.startNode = rootNode
        }

        func run() -> PGNDecodeResult {
            let total = max(tokens.count, 1)
            for (index, token) in tokens.enumerated() {
                process(token)
                if index % 256 == 0 {
                    onProgress(Double(index) / Double(total))
                }
            }
            finalizeGame()
            return PGNDecodeResult(nodes: allNodes, warnings: warnings)
        }

        private func process(_ token: PGNDecoder.Token) {
            switch token {
            case .tagPair(let key, let value):
                if inMovetext { finalizeGame() }
                pendingTags[key] = value

            case .move(let san):
                ensureGameStarted()
                guard !gameSkipped, !gameFailed else { return }
                handleMove(san)

            case .comment(let text):
                ensureGameStarted()
                guard !gameSkipped else { return }
                if !text.isEmpty { addComment(text) }

            case .nag:
                ensureGameStarted()  // NAGs are currently ignored

            case .variationStart:
                ensureGameStarted()
                guard !gameSkipped, !gameFailed else { return }
                startVariation()

            case .variationEnd:
                guard !gameSkipped, !gameFailed else { return }
                endVariation()

            case .termination:
                ensureGameStarted()
                finalizeGame()
            }
        }

        // MARK: Game lifecycle

        private func ensureGameStarted() {
            guard !inMovetext else { return }
            inMovetext = true
            gameFailed = false
            gameSkipped = false
            variationStack.removeAll()
            branchNode = nil
            branchGame = nil
            gameIndex += 1

            if let node = startingNode(for: pendingTags) {
                startNode = node
                currentNode = node
            } else {
                gameSkipped = true
            }
        }

        private func finalizeGame() {
            if inMovetext, !variationStack.isEmpty {
                warnings.append("Game \(gameIndex): unbalanced parentheses in variations.")
            }
            inMovetext = false
            pendingTags = [:]
            variationStack.removeAll()
            branchNode = nil
            branchGame = nil
        }

        /// Determines the starting node and game for a new game based on its tags.
        private func startingNode(for tags: [String: String]) -> GameNode? {
            guard let fen = tags["FEN"], normalizedFEN(fen) != startingFEN else {
                game = Game(position: startingGamePosition)
                return rootNode
            }
            guard isPlausibleFEN(fen) else {
                warnings.append("Game \(gameIndex): skipped, malformed FEN tag.")
                return nil
            }
            let position = FenSerialization.default.deserialize(fen: fen)
            if let node = dictBoardNode[position.board] {
                game = Game(position: position)
                return node
            }
            warnings.append("Game \(gameIndex): skipped, setup position is not part of this study.")
            return nil
        }

        // MARK: Moves

        private func handleMove(_ san: String) {
            let annotation = extractAnnotation(san)
            do {
                let move = try resolveMove(san, in: game)
                let canonical = SanSerialization.default.correctSan(for: move, in: game)

                let parent = currentNode
                let preGame = game.deepCopy()
                game.make(move: move)
                let newPosition = game.position

                let key = Parser.positionKey(newPosition)
                let child: GameNode
                if let existing = parent.children.first(where: { $0.moveString == canonical }) {
                    child = existing.child
                } else if let transposition = dictNode[key] {
                    let moveNode = MoveNode(moveString: canonical, move: move,
                                            annotation: annotation, child: transposition, parent: parent)
                    parent.children.append(moveNode)
                    transposition.parents.append(moveNode)
                    child = transposition
                } else {
                    let fen = FenSerialization.default.serialize(position: newPosition)
                    let node = GameNode(fen: fen)
                    let moveNode = MoveNode(moveString: canonical, move: move,
                                            annotation: annotation, child: node, parent: parent)
                    parent.children.append(moveNode)
                    node.parents.append(moveNode)
                    allNodes.append(node)
                    dictNode[key] = node
                    dictBoardNode[newPosition.board] = node
                    child = node
                }

                branchNode = parent
                branchGame = preGame
                currentNode = child
            } catch let error as PGNDecodingError {
                warnings.append("Game \(gameIndex): \(error.localizedDescription) Rest of game skipped.")
                gameFailed = true
            } catch {
                warnings.append("Game \(gameIndex): \(error.localizedDescription)")
                gameFailed = true
            }
        }

        private func startVariation() {
            variationStack.append(LineState(node: currentNode, game: game,
                                            branchNode: branchNode, branchGame: branchGame))
            if let bNode = branchNode, let bGame = branchGame {
                currentNode = bNode
                game = bGame.deepCopy()
            }
            // If there is no branch point yet, the variation degenerately starts
            // from the current position; nothing else to do.
            branchNode = nil
            branchGame = nil
        }

        private func endVariation() {
            guard let state = variationStack.popLast() else {
                warnings.append("Game \(gameIndex): unmatched ')' ignored.")
                return
            }
            currentNode = state.node
            game = state.game
            branchNode = state.branchNode
            branchGame = state.branchGame
        }

        private func addComment(_ text: String) {
            if currentNode.comment == nil {
                currentNode.comment = text
            } else {
                currentNode.comment! += "\n\n" + text
            }
        }

        // MARK: SAN resolution

        /// Resolves a SAN string to the unique legal `Move` it denotes, throwing
        /// a `PGNDecodingError` if it is illegal, ambiguous or malformed.
        private func resolveMove(_ raw: String, in game: Game) throws -> Move {
            var s = stripAnnotations(raw)
            s = s.replacingOccurrences(of: "+", with: "")
                 .replacingOccurrences(of: "#", with: "")
                 .replacingOccurrences(of: "e.p.", with: "")
                 .trimmingCharacters(in: .whitespaces)

            // Castling (accept both "O" and "0" spellings).
            let castle = s.replacingOccurrences(of: "0", with: "O")
            if castle == "O-O" || castle == "O-O-O" {
                let targetFile = castle == "O-O" ? 6 : 2
                let candidates = game.legalMoves.filter {
                    game.position.board[$0.from]?.kind == .king &&
                    $0.from.file == 4 && $0.to.file == targetFile
                }
                if let move = candidates.first { return move }
                throw PGNDecodingError.illegalMove(san: raw, fen: fen(of: game))
            }

            let pattern = #"^([KQRBN])?([a-h])?([1-8])?x?([a-h][1-8])=?([QRBN])?$"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else {
                throw PGNDecodingError.malformedSAN(raw)
            }

            func group(_ index: Int) -> String? {
                guard let range = Range(match.range(at: index), in: s) else { return nil }
                return String(s[range])
            }

            let pieceKind = group(1).flatMap { PieceKind(rawValue: $0.lowercased()) } ?? .pawn
            let toSquare = Square(coordinate: group(4)!)
            let promotion = group(5).flatMap { PieceKind(rawValue: $0.lowercased()) }
            let fromFile = group(2).map { Int($0.unicodeScalars.first!.value) - 97 }   // 'a' = 0
            let fromRank = group(3).flatMap { Int($0) }.map { $0 - 1 }                  // '1' = 0

            var candidates = game.legalMoves.filter {
                $0.to == toSquare && game.position.board[$0.from]?.kind == pieceKind
            }
            if let promotion {
                candidates = candidates.filter { $0.promotion == promotion }
            } else if candidates.contains(where: { $0.promotion != nil }) {
                // Promotion piece omitted by the source; default to a queen.
                candidates = candidates.filter { $0.promotion == .queen }
            }
            if let fromFile { candidates = candidates.filter { $0.from.file == fromFile } }
            if let fromRank { candidates = candidates.filter { $0.from.rank == fromRank } }

            switch candidates.count {
            case 1:
                return candidates[0]
            case 0:
                throw PGNDecodingError.illegalMove(san: raw, fen: fen(of: game))
            default:
                throw PGNDecodingError.ambiguousMove(san: raw, fen: fen(of: game))
            }
        }

        private func fen(of game: Game) -> String {
            FenSerialization.default.serialize(position: game.position)
        }

        /// A transposition key for a position: the board plus side-to-move,
        /// castling rights, en-passant square *and the full-move number*, but not
        /// the half-move (50-move) clock.
        ///
        /// The full-move number is kept on purpose. Two genuine transpositions
        /// reorder the *same* moves, so they reach the position at the same move
        /// number and still share a node. A line that *repeats* a position returns
        /// to it at a strictly higher move number, so it gets its own node instead
        /// of looping an edge back onto an ancestor. That keeps the graph acyclic
        /// (an ancestor with the same board always has a lower move number, so it
        /// can never key-match) which every tree walker relies on to terminate.
        ///
        /// The half-move clock is still zeroed: it legitimately differs between two
        /// transpositions (capture/pawn-push timing depends on move order), and
        /// keeping it would wrongly split them into separate nodes.
        private static func positionKey(_ position: Position) -> Position {
            var key = position
            key.counter.halfMoves = 0
            return key
        }
    }
}

// MARK: - SAN helpers

/// Strips trailing annotation glyphs (`!`, `?`, `!?`, `??`, …) from a SAN string.
private func stripAnnotations(_ san: String) -> String {
    var s = san
    let glyphs = ["!?", "?!", "!!", "??", "!", "?"]
    var changed = true
    while changed {
        changed = false
        for glyph in glyphs where s.hasSuffix(glyph) {
            s = String(s.dropLast(glyph.count))
            changed = true
        }
    }
    return s
}

/// Returns the annotation glyph suffix of a SAN string, or `nil` if there is none.
private func extractAnnotation(_ san: String) -> String? {
    let glyphs = ["!?", "?!", "!!", "??"]
    for glyph in glyphs where san.hasSuffix(glyph) { return glyph }
    if san.hasSuffix("!") { return "!" }
    if san.hasSuffix("?") { return "?" }
    return nil
}

/// Lightweight sanity check that a FEN string is well formed enough to deserialize.
private func isPlausibleFEN(_ fen: String) -> Bool {
    let fields = fen.split(separator: " ")
    guard fields.count >= 2 else { return false }
    let ranks = fields[0].split(separator: "/")
    guard ranks.count == 8 else { return false }
    let allowed = Set("rnbqkpRNBQKP12345678")
    return ranks.allSatisfy { $0.allSatisfy { allowed.contains($0) } }
}

/// Normalizes a FEN to its board/turn/castling/en-passant fields so that a
/// study's setup FEN can be compared against the standard start position even
/// if the move counters differ.
private func normalizedFEN(_ fen: String) -> String {
    let fields = fen.split(separator: " ")
    guard fields.count >= 4 else { return fen }
    return fields.prefix(4).joined(separator: " ") == startingFEN.split(separator: " ").prefix(4).joined(separator: " ")
        ? startingFEN
        : fen
}
