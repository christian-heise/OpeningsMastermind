//
//  PractiseViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 06.05.23.
//

import Foundation
import ChessKit

//extension PractiseView {
    @MainActor class PractiseViewModel: ObservableObject {
        @Published var gameTree: GameTree?
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
        
        func revertMove() {
            guard let gameTree = self.gameTree else { return }
            self.game = gameTree.gameCopy ?? Game(position: startingGamePosition)
            gameTree.gameState = 0
            objectWillChange.send()
        }
        
        func resetGameTree(to newGameTree: GameTree? = nil) {
            if let newGameTree = newGameTree {
                self.game = Game(position: startingGamePosition)
                self.gameTree = newGameTree
                if newGameTree.userColor == .black {
                    Task {
                        await makeNextMove(in: 0)
                    }
                } else {
                    objectWillChange.send()
                }
            } else {
                guard let gameTree = self.gameTree else { return }
                self.game = Game(position: startingGamePosition)
                gameTree.reset()
                if gameTree.userColor == .black {
                    Task {
                        await makeNextMove(in: 0)
                    }
                } else {
                    objectWillChange.send()
                }
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
            
//            if gameTree.currentNode!.mistakesLast10Moves.count == 10 {
//                gameTree.currentNode!.mistakesLast10Moves.removeFirst()
//            }
            
            if success {
//                gameTree.currentNode!.mistakesLast10Moves.append(0)
                gameTree.currentNode = newNode
                self.game.make(move: move)
                gameTree.gameState = 0
                Task {
                    await makeNextMove(in: 0)
                }
            } else {
                gameTree.gameCopy = self.game.deepCopy()
                if !gameTree.currentNode!.children.isEmpty {
                    gameTree.currentNode!.mistakesLast10Moves.append(1)
                    gameTree.gameState = 1
                    
                    determineRightMove()
                } else {
                    print("Hä")
                }
                game.make(move: move)
                
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
    }


//}
