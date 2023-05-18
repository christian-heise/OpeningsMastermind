//
//  PractiseViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 06.05.23.
//

import Foundation
import ChessKit

//extension PractiseView {
    class PracticeViewModel: ParentChessBoardModelProtocol {
        @Published var gameTree: GameTree?
        @Published var moveStringList: [String] = []
        
        var moveString: String {
            var result = ""

            for i in stride(from: 0, to: moveStringList.count, by: 2) {
                let index = i / 2 + 1
                let element1 = moveStringList[i]
                let element2 = i + 1 < moveStringList.count ? moveStringList[i+1] : ""
                result += "\(index). \(element1) \(element2) "
            }

            return result
        }
        
        init(gameTree: GameTree? = nil) {
            self.gameTree = gameTree
        }
        
        var game: Game = Game(position: startingGamePosition)
        
        var lastMove: Move? {
            return self.game.movesHistory.last
        }
        
        var last2Moves: (Move?, Move?) {
            if self.game.movesHistory.count > 1 {
                return (game.movesHistory.suffix(2).last, game.movesHistory.suffix(2).first)
            } else if self.game.movesHistory.count == 1 {
                return (game.movesHistory.first, nil)
            } else {
                return (nil, nil)
            }
        }
        
        var userColor: PieceColor {
            if let gameTree = self.gameTree {
                return gameTree.userColor
            } else {
                return .white
            }
        }
        
        var promotionPending: Bool = false
        
        var gameState: Int {
            if let gameTree = self.gameTree {
                return gameTree.gameState
            } else {
                return -1
            }
        }
        
        var pieces: [(Square, Piece)] {
            return game.position.board.enumeratedPieces()
        }
        
        var rightMove: [Move] = []
        
        var annotation: (String?, String?) {
            guard let currentNode = self.gameTree?.currentNode else { return (nil,nil) }
            
            if let parentNode = currentNode.parent {
                return (currentNode.annotation, parentNode.annotation)
            } else {
                return (currentNode.annotation, nil)
            }
        }
        
        var promotionMove: Move? = nil
        
        func onAppear(database: DataBase) {
            if database.gametrees.isEmpty {
                self.gameTree = nil
                return
            }
            
            guard let gametree = self.gameTree else {
                resetGameTree(to: database.gametrees.max(by: {$0.lastPlayed < $1.lastPlayed}))
                return
            }
            
            if !database.gametrees.contains(gametree) {
                resetGameTree(to: database.gametrees.max(by: {$0.lastPlayed < $1.lastPlayed}))
            } else if database.gametrees.max(by: {$0.lastPlayed < $1.lastPlayed})!.lastPlayed < database.gametrees.max(by: {$0.date < $1.date})!.date {
                resetGameTree(to: database.gametrees.max(by: {$0.date < $1.date}))
            }
        }
        
        func revertMove() {
            guard let gameTree = self.gameTree else { return }
            self.game = gameTree.gameCopy ?? Game(position: startingGamePosition)
            gameTree.gameState = 0
            objectWillChange.send()
        }
        
        func resetGameTree(to newGameTree: GameTree? = nil) {
            self.moveStringList = []
            self.game = Game(position: startingGamePosition)
            
            if let newGameTree = newGameTree {
                newGameTree.lastPlayed = Date()
                newGameTree.reset()
                self.gameTree = newGameTree
            } else {
                guard let gameTree = self.gameTree else { return }
                gameTree.reset()
            }
            
            if self.userColor == .black {
                Task {
                    await makeNextMove(in: 0)
                }
            } else {
                objectWillChange.send()
            }
        }
        
        func makeNextMove(in time_ms: Int) async {
            guard let gameTree = self.gameTree else { return }
            if gameTree.currentNode!.children.isEmpty {
                gameTree.gameState = 2
                objectWillChange.send()
                return
            }
            let (newMove, newNode) = gameTree.generateMove(game: game)
            
            try? await Task.sleep(for: .milliseconds(time_ms))
            
            await MainActor.run {
                let san = SanSerialization.default.correctSan(for: newMove!, in: self.game)

                self.moveStringList.append(san)
                self.game.make(move: newMove!)
                if newNode!.children.isEmpty {
                    gameTree.gameState = 2
                }
                gameTree.currentNode = newNode!
                objectWillChange.send()
            }
            
        }
        
        func processMove(piece: Piece, from oldSquare: Square, to newSquare: Square) {
            guard let gameTree = self.gameTree else { return }

            if piece.kind == .pawn {
                if newSquare.rank == 7 || newSquare.rank == 0 {
                    let move = Move(from: oldSquare, to: newSquare, promotion: .queen)
                    if game.legalMoves.contains(move) {
                        gameTree.gameState = 3
                        self.promotionMove = move
                        objectWillChange.send()
                        return
                    }
                }
            }
            
            let move = Move(from: oldSquare, to: newSquare)
            if !game.legalMoves.contains(move) {
                return
            }
            makeMove(move)
        }
        
        func makeMove(_ move: Move) {
            guard let gameTree = self.gameTree else { return }
            let (success, newNode) = gameTree.currentNode!.databaseContains(move: move, in: self.game)
            
            if success {
                addMistake(0)
                gameTree.currentNode = newNode
                self.moveStringList.append(SanSerialization.default.correctSan(for: move, in: self.game))
                self.game.make(move: move)
                gameTree.gameState = 0
                Task {
                    await makeNextMove(in: 300)
                }
            } else {
                gameTree.gameCopy = self.game.deepCopy()
                if !gameTree.currentNode!.children.isEmpty {
                    addMistake(1)
                    gameTree.gameState = 1
                    
                    determineRightMove()
                    game.make(move: move)
                    
                } else {
                    print("Hä")
                    gameTree.gameState = 2
                }
                objectWillChange.send()
            }
        }
        
        func determineRightMove() {
            guard let currentNode = self.gameTree?.currentNode else { return }
            self.rightMove = []
            let decoder = SanSerialization.default
            for node in currentNode.children {
                self.rightMove.append(decoder.move(for: node.move, in: self.game))
            }
        }
        
        func processPromotion(_ kind: PieceKind) {
            guard let promotionMove = self.promotionMove else { return }
            self.promotionMove = nil
            makeMove(Move(from: promotionMove.from, to: promotionMove.to, promotion: kind))
        }
        
        func addMistake(_ mistake: Int) {
            guard let gameTree = self.gameTree else { return }
            gameTree.currentNode!.mistakesLast5Moves.removeFirst()
            gameTree.currentNode!.mistakesLast5Moves.append(mistake)
        }
    }


//}
