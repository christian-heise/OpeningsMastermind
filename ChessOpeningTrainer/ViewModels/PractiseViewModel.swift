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
        
        var userColor: PieceColor {
            if let gameTree = self.gameTree {
                return gameTree.userColor
            } else {
                return .white
            }
        }
        
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
        
        func revertMove() {
            guard let gameTree = self.gameTree else { return }
            self.game = gameTree.gameCopy ?? Game(position: startingGamePosition)
            gameTree.gameState = 0
            objectWillChange.send()
        }
        
        func resetGameTree() {
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
        func makeNextMove(in time_ms: Int) async {
            guard let gameTree = self.gameTree else { return }
            if gameTree.currentNode!.children.isEmpty {
                gameTree.gameState = 2
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
        
        func processMove(_ move: Move) {
            guard let gameTree = self.gameTree else { return }
            
            if !game.legalMoves.contains(move) {
                return
            }
            let (success, newNode) = gameTree.currentNode!.databaseContains(move: move, in: game)
            
//            if gameTree.currentNode!.mistakesLast10Moves.count == 10 {
//                gameTree.currentNode!.mistakesLast10Moves.removeFirst()
//            }
            
            if success {
//                gameTree.currentNode!.mistakesLast10Moves.append(0)
                gameTree.currentNode = newNode
                self.game.make(move: move)
                Task {
                    await makeNextMove(in: 0)
                }
            } else {
                gameTree.gameCopy = self.game.deepCopy()
                if !gameTree.currentNode!.children.isEmpty {
                    gameTree.currentNode!.mistakesLast10Moves.append(1)
                    gameTree.gameState = 1
                    
                    determineRightMove()
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
    }
//}
