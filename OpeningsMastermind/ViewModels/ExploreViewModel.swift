//
//  ExploreViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import Foundation
import ChessKit
import ChessKitEngine

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
    let settings: Settings
    var gameTree: GameTree?
    
    var engine: Engine?
    
    @Published var lichessResponse: LichessOpeningData?
    @Published var currentExploreNode: ExploreNode
    @Published var evaluation: Double?
    @Published var mateInXMoves: Int?
    
    var rootExploreNode: ExploreNode
    
    let userRating: Int?
    
    private var dataTask: URLSessionDataTask?
    private var lichessCache: [String: LichessOpeningData] = [:]
    private var currentLichessTask: Task<(), Never>?
    
    private var engineCache: [String: Double] = [:]
    
    var comment: String {
        guard let comment = currentExploreNode.gameNode?.comment else { return ""}
        
        let regex = try! NSRegularExpression(pattern: "\\[%cal.*?\\]", options: .dotMatchesLineSeparators)
        let output = regex.stringByReplacingMatches(in: comment, options: [], range: NSRange(location: 0, length: comment.utf16.count), withTemplate: "")
        
        if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ""
        } else {
            return output
        }
    }
    
    var currentMoveColor: PieceColor {
        return currentExploreNode.color
    }

    init(database: DataBase, settings: Settings) {
        if settings.engineOn {
            engine = Engine(type: .stockfish)
        } else {
            engine = nil
        }
        self.database = database
        self.settings = settings
        self.userRating = settings.playerRating
        
        self.rootExploreNode = ExploreNode()
        self.currentExploreNode = self.rootExploreNode
        super.init()
        
        if let engine = engine {
            engine.start(coreCount: 3)
        }
//        engine?.loggingEnabled = true
        onAppear()
    }
    
    func onAppear() {
        if settings.engineOn && engine == nil {
            self.engine = Engine(type: .stockfish)
            self.engine!.start(coreCount: 3)
        }
        if !settings.engineOn, let engine = self.engine {
            engine.stop()
            self.engine = nil
        }
        if let engine = engine {
            engine.send(command: .stop)
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
    
    func updateLichessExplorer() {
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
    
    func getLichessMoves() async -> LichessOpeningData? {
        let ratingRange = (self.userRating ?? 1800 - 300, self.userRating ?? 2200 + 300)
        let fen = FenSerialization.default.serialize(position: self.game.position).replacingOccurrences(of: " ", with: "%20")
        if let cachedResult = lichessCache[fen] {
            return cachedResult
        }
        do {
            try await Task.sleep(for: .milliseconds(200))
        } catch {
            print("Sleeping somehow failed")
        }
        
        let urlString = "https://explorer.lichess.ovh/lichess?variant=standard&speeds=blitz,rapid,classical&ratings=\(ratingRange.0),\(ratingRange.1)&fen=\(fen)"
        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return nil}
        
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            print("URL Session Failed")
            return nil}
        
        guard let decodedData = try? JSONDecoder().decode(LichessOpeningData.self, from: data) else { return nil }
        
        lichessCache[fen] = decodedData
        return decodedData
    }
    
    func getEngineMoves() {
        guard let engine = engine else { return }
        let position = self.game.position
        let fen = FenSerialization.default.serialize(position: position)
        let color = self.currentExploreNode.color
        
        guard engineCache[fen] == nil  else {
            self.evaluation = engineCache[fen]
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            engine.send(command: .stop)
            engine.send(command: .position(.fen(fen)))
            engine.send(command: .go(depth: 18))
            engine.receiveResponse = { response in
                DispatchQueue.main.async {
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
                    default:
                        break
                    }
                }
            }
        }
    }
    
    override func postMoveStuff() {
        self.promotionMove = nil
        self.promotionPending = false
        
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
