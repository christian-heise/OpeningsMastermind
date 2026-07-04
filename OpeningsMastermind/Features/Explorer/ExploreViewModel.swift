//
//  ExploreViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import Foundation
import ChessKit
import ChessKitEngine
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpeningsMastermind", category: "ExploreViewModel")

@MainActor class ExploreViewModel: ParentChessBoardModel, ParentChessBoardModelProtocol {
    
    @Published var userColor = PieceColor.white
    @Published var showingComment = false
    
    var annotation: (String?, String?) {
        guard let node = currentExploreNode.gameNode else { return (nil, nil)}
        
        guard let moveNode = node.parents.first(where: {$0.move == moveHistory[positionIndex].0}) else { return (nil, nil) }
        
        if let annotation = moveNode.annotation {
            return (annotation, nil)
        } else {
            return (nil, nil)
        }
    }
    
    let database: DataBase
    let appData: AppData
    var gameTree: GameTree?

    /// Injected at init time for SwiftUI previews; bypasses the Lichess network
    /// call so the explorer panel shows realistic data without a real token.
    private let previewLichessData: LichessOpeningData?
    
    /// The process-wide shared engine. It is **not** owned per–view model: Stockfish
    /// can only run once per process, and a second started `Engine` corrupts the
    /// shared stdin/stdout (see `EngineWrapper.shared`). Response routing is claimed
    /// by whichever view model is currently appearing, in `onAppear()`.
    private var engineWrapper: EngineWrapper { .shared }

    /// Whether the user currently wants engine evaluations. Gates analysis requests
    /// without stopping the (long-lived) engine.
    private var engineRequestsEnabled = false
    
    @Published var lichessResponse: LichessOpeningData?
    @Published var currentExploreNode: ExploreNode
    @Published var evaluation: Double?
    @Published var mateInXMoves: Int?
    @Published var engineMove: String?
    
    var rootExploreNode: ExploreNode
    
    let userRating: Int?
    
    private var dataTask: URLSessionDataTask?
    private var lichessCache: [String: LichessOpeningData] = [:]
    private var currentLichessTask: Task<(), Never>?
    
    private var engineCache: [String: Double] = [:]
    
    var comment: String {
        guard let comment = currentExploreNode.gameNode?.comment else { return ""}
        
        let regex = try! NSRegularExpression(pattern: "\\[%cal.*?\\]|\\[%csl.*?\\]", options: .dotMatchesLineSeparators)
        let output = regex.stringByReplacingMatches(in: comment, options: [], range: NSRange(location: 0, length: comment.utf16.count), withTemplate: "")
        
        let trimmedString = output.replacingOccurrences(of: "\\s*\n\\s*", with: "\n", options: .regularExpression)
        
        return trimmedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var currentMoveColor: PieceColor {
        return currentExploreNode.color
    }

    init(database: DataBase, appData: AppData, previewLichessData: LichessOpeningData? = nil) {
        self.database = database
        self.appData = appData
        self.previewLichessData = previewLichessData
        self.userRating = appData.settings.playerRating

        self.rootExploreNode = ExploreNode()
        self.currentExploreNode = self.rootExploreNode
        super.init()

        // NOTE: deliberately do **not** call `onAppear()` here. `onAppear()`
        // claims the shared engine's single `responseHandler` slot, and SwiftUI
        // re-inits `ContentView` (a struct) several times during launch — each
        // re-init builds a throwaway `ExploreViewModel` that `@StateObject`
        // discards. If a throwaway claimed the handler here, it could win the
        // slot *after* the live VM did, leaving the handler captured on a
        // deallocated VM (`self == nil`) so engine responses are dropped and no
        // evaluation ever shows until a tab switch re-fires the view's
        // `.onAppear`. Only the on-screen view (via `ExploreView.onAppear`)
        // should drive `onAppear()`, so only the live retained VM claims it.
    }
    
    func onAppear() {
        // SwiftUI previews run in a sandboxed agent that never settles while the
        // engine/network tasks churn, causing the canvas to time out. Skip all
        // external work there and just set up the board state below.
        if !ProcessInfo.isRunningInPreviews {
            if appData.settings.engineOn {
                engineRequestsEnabled = true
                let wrapper = engineWrapper
                // Claim response routing for this (the currently-appearing) view
                // model; the shared engine has a single handler slot.
                wrapper.responseHandler = { [weak self] response in
                    self?.receiveEngineReponse(response: response)
                }
                Task { await wrapper.start() } // idempotent: starts Stockfish once, resumes otherwise
            } else if engineRequestsEnabled {
                engineRequestsEnabled = false
                engineWrapper.pauseAnalysis()
            }

            getEngineMoves()

            // Pick up a sign-in that happened on another tab (e.g. Settings): the
            // panel becomes visible but has no data until the next move otherwise.
            if isSignedInToLichess && lichessResponse == nil {
                updateLichessExplorer()
            }
        }

        if database.gametrees.isEmpty {
            self.gameTree = nil
            self.reset()
            return
        }

        guard let gametree = self.gameTree else {
            reset(to: database.gametrees.max(by: {$0.dateLastPlayed < $1.dateLastPlayed})!)
            return
        }

        if !database.gametrees.contains(gametree) {
            reset(to: database.gametrees.max(by: {$0.dateLastPlayed < $1.dateLastPlayed})!)
        }
    }
    
    func reset() {
        self.rootExploreNode = ExploreNode(gameNode: gameTree?.rootNode)
        self.currentExploreNode = self.rootExploreNode
        self.game = Game(position: startingGamePosition)
        
        self.userColor = self.gameTree?.userColor ?? .white
        
        self.moveHistory = []
        self.positionHistory = []
        self.positionIndex = -1
        self.promotionMove = nil
        self.showingComment = false
        gameState = .explore
        
        self.updateLichessExplorer()
        self.determineRightMove()
        self.getEngineMoves()
    }
    
    func reset(to newGameTree: GameTree) {
        self.gameTree = newGameTree
        self.rootExploreNode = ExploreNode(gameNode: newGameTree.rootNode)
        self.currentExploreNode = self.rootExploreNode

        self.game = Game(position: startingGamePosition)
        
        self.userColor = newGameTree.userColor
        
        self.moveHistory = []
        self.positionHistory = []
        self.positionIndex = -1
        self.promotionMove = nil
        self.showingComment = false
        gameState = .explore
        
        self.updateLichessExplorer()
        self.determineRightMove()
        self.getEngineMoves()
    }
    
    func determineRightMove() {
        self.rightMove = []
        
        guard let gameNode = currentExploreNode.gameNode else { return }
        
        for node in gameNode.children {
            self.rightMove.append(node.move)
        }
    }
    
    override func performMove(_ move: Move) {
        if !game.legalMoves.contains(move) { return }
        
        self.moveHistory = Array(self.moveHistory.prefix(self.positionIndex+1))
        self.positionHistory = Array(self.positionHistory.prefix(self.positionIndex+1))
        
        let moveString = SanSerialization.default.correctSan(for: move, in: self.game)
        
        if self.positionIndex + 1 != self.positionHistory.count {
            self.positionHistory = Array(self.positionHistory.prefix(self.positionIndex+1))
        }
        self.positionHistory.append(self.game.position)
        self.moveHistory.append((move, moveString))
        self.positionIndex = self.positionIndex + 1
        
        if let node = currentExploreNode.children.first(where: {$0.move == moveString}) {
            currentExploreNode = node
        } else {
            let newColor: PieceColor = currentExploreNode.color.negotiated
            if let moveNode = currentExploreNode.gameNode?.children.first(where: {$0.moveString == moveString}) {
                let gameNode = moveNode.child
                
                let newNode = ExploreNode(gameNode: gameNode, move: moveString, parentNode: currentExploreNode, position: game.position, color: newColor)
                currentExploreNode.children.append(newNode)
                currentExploreNode = newNode
            } else {
                let newNode = ExploreNode(gameNode: nil, move: moveString, parentNode: currentExploreNode, position: game.position, color: newColor)
                currentExploreNode.children.append(newNode)
                currentExploreNode = newNode
            }
        }
        
        self.game.make(move: move)
    }
    
    func jump(to index: Int) {
        if index == positionIndex {
            print("Same Index")
            return
        } else if index > positionIndex {
            for _ in 0..<(index - positionIndex) {
                forwardMove()
            }
        } else {
            for _ in 0..<(positionIndex - index) {
                reverseMove()
            }
        }
        postMoveStuff()
    }
    
    func makeLichessMove(san: String) {
        guard !ProcessInfo.isRunningInPreviews else { return }
        let move = SanSerialization.default.move(for: san, in: game)
        performMove(move)
        postMoveStuff()
    }
    
    func makeMainLineMove() {
        guard let move = currentExploreNode.gameNode?.children.first?.move else {return}
        self.performMove(move)
    }
    
    func forwardOneMove() {
        forwardMove()
        postMoveStuff()
    }
    
    func forwardMove() {
        if self.positionIndex + 1 != self.positionHistory.count {
            self.positionIndex += 1
            
            let moveString = self.moveHistory[positionIndex].1
            
            currentExploreNode = currentExploreNode.children.first(where: {$0.move == moveString})!
            
            self.game.make(move: self.moveHistory[positionIndex].0)
        } else {
            makeMainLineMove()
        }
    }
    
    func reverseOneMove() {
        reverseMove()
        postMoveStuff()
    }
    
    func reverseMove() {
        guard self.positionIndex >= 0 else {return}
        
        self.game = Game(position: positionHistory[positionIndex], moves: Array(self.game.movesHistory.prefix(positionIndex)))
        self.positionIndex -= 1
        
        currentExploreNode = currentExploreNode.parent!
    }
    
    var isSignedInToLichess: Bool { appData.lichessAuth.isSignedIn }

    /// True when the explorer panel should be visible — either the user is
    /// signed in to Lichess, or preview data has been injected for SwiftUI canvas.
    var showLichessExplorer: Bool { isSignedInToLichess || previewLichessData != nil }

    /// Runs the Lichess OAuth flow from the explorer's inline prompt and
    /// refreshes the move statistics on success. Cancellation is silent.
    func signInToLichess() async {
        do {
            try await appData.signInToLichess()
            updateLichessExplorer()
        } catch LichessAuthError.cancelled {
            // User dismissed the sign-in sheet; nothing to do.
        } catch {
            logger.warning("Lichess sign-in failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func updateLichessExplorer() {
        if let previewData = previewLichessData {
            lichessResponse = previewData
            return
        }
        currentLichessTask?.cancel()
        lichessResponse = nil
        let task = Task {
            let lichessResponse = await getLichessMoves()

            await MainActor.run {
                self.lichessResponse = lichessResponse
            }
        }
        currentLichessTask = task
    }
    
    /// Rating buckets accepted by the Lichess opening-explorer API. Each bucket
    /// covers ratings from its value up to the next bucket; arbitrary values are
    /// rejected, so the requested rating must be mapped onto these.
    private static let lichessRatingBuckets = [0, 1000, 1200, 1400, 1600, 1800, 2000, 2200, 2500]

    /// The comma-separated list of valid Lichess rating buckets covering roughly
    /// ±300 around the user's rating (defaulting to 1800 when unknown).
    private var lichessRatingsParameter: String {
        let rating = userRating ?? 1800
        let lower = rating - 300
        let upper = rating + 300
        let buckets = Self.lichessRatingBuckets
        // Include the bucket containing `lower` so the band isn't truncated.
        let lowerBucket = buckets.last(where: { $0 <= lower }) ?? buckets.first!
        let selected = buckets.filter { $0 >= lowerBucket && $0 <= upper }
        return (selected.isEmpty ? [lowerBucket] : selected)
            .map(String.init)
            .joined(separator: ",")
    }

    func getLichessMoves() async -> LichessOpeningData? {
        // Lichess gated the opening-explorer host behind authentication; an
        // unauthenticated request just gets a 401. Skip entirely when signed out.
        guard let token = appData.lichessAuth.token else { return nil }

        let fen = FenSerialization.default.serialize(position: self.game.position).replacingOccurrences(of: " ", with: "%20")
        if let cachedResult = lichessCache[fen] {
            return cachedResult
        }
        // Debounce: when this request is superseded the task is cancelled and
        // `sleep` throws. That's the normal path, not an error — bail silently.
        do {
            try await Task.sleep(for: .milliseconds(200))
        } catch {
            return nil
        }

        let urlString = "https://explorer.lichess.ovh/lichess?variant=standard&speeds=blitz,rapid,classical&ratings=\(lichessRatingsParameter)&fen=\(fen)"
        guard let url = URL(string: urlString) else {
            logger.error("Bad Lichess explorer URL")
            return nil}

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch is CancellationError {
            return nil
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Superseded by a newer position; not a real failure.
            return nil
        } catch {
            logger.warning("Lichess explorer request failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        if (response as? HTTPURLResponse)?.statusCode == 401 {
            // Token was revoked or expired: drop it so the UI prompts a re-sign-in.
            appData.lichessAuth.handleUnauthorized()
            return nil
        }

        guard let decodedData = try? JSONDecoder().decode(LichessOpeningData.self, from: data) else { return nil }

        lichessCache[fen] = decodedData
        return decodedData
    }
    
    func getEngineMoves() {
        let fen = FenSerialization.default.serialize(position: self.game.position)

        if let cached = engineCache[fen] {
            self.evaluation = cached
            return
        }

        if engineRequestsEnabled {
            engineWrapper.analyzePosition(fen: fen)
        }
    }
    
    func receiveEngineReponse(response: EngineResponse) {
        let color = self.currentExploreNode.color
        switch response {
        case let .info(info):
            if let score = info.score?.cp {
                self.mateInXMoves = nil
                if color == .white {
                    self.evaluation = score / 100.0
                } else {
                    self.evaluation = -score / 100.0
                }
            }
            if let mateInXMoves = info.score?.mate {
                if color == .white {
                    if mateInXMoves == 0 {
                        self.evaluation = -50
                    } else {
                        self.evaluation = 10 * Double(mateInXMoves)
                    }
                    self.mateInXMoves = mateInXMoves
                } else {
                    if mateInXMoves == 0 {
                        self.evaluation = 50
                    } else {
                        self.evaluation = -10 * Double(mateInXMoves)
                    }
                    self.mateInXMoves = -mateInXMoves
                }
            }
        case let .bestmove(move: moveString, ponder: _):
            self.engineMove = SanSerialization.default.san(for: Move(string: moveString), in: self.game)
        default:
            break
        }
    }
    
    override func postMoveStuff() {
        self.promotionMove = nil
        self.promotionPending = false
        
        self.engineMove = nil
        
        selectedSquare = nil
        getEngineMoves()
        determineRightMove()
        updateLichessExplorer()
        showingComment = false
        gameState = .explore
    }
    
    
}
class ExploreNode {
    var parent: ExploreNode?
    var move: String
    var children: [ExploreNode]
    let gameNode: GameNode?
//    let position: Position
    let color: PieceColor
    
    var evaluation: Double?
    
    init(gameNode: GameNode? = nil, move: String="", parentNode: ExploreNode? = nil, position: Position = startingGamePosition, color: PieceColor = .white) {
        self.parent = parentNode
        self.children = []
        self.gameNode = gameNode
//        self.position = position
        self.move = move
        self.color = color
    }
}
