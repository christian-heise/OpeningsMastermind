//
//  ExploreViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import Foundation
import ChessKit

class ExploreViewModel: ParentChessBoardModelProtocol {
    init(gameTree: GameTree? = nil) {
        self.gameTree = gameTree
    }
    
    @Published var gameTree: GameTree?
    @Published var moveStringList: [String] = []
    
    
    
    var rightMove: [Move] = []
    var game: Game = Game(position: startingGamePosition)
    var promotionMove: Move? = nil
    var moveHistory: [(Move, String)] = []
    var positionHistory: [Position] = []
    var positionIndex: Int = -1
    
    var pieces: [(Square, Piece)] {
        return game.position.board.enumeratedPieces()
    }
    
    var comment: String {
        return gameTree?.currentNode?.comment ?? ""
    }
    
    var annotation: (String?, String?) {
        guard let currentNode = self.gameTree?.currentNode else { return (nil,nil) }
        
        if let parentNode = currentNode.parent {
            return (currentNode.annotation, parentNode.annotation)
        } else {
            return (currentNode.annotation, nil)
        }
    }
    
    var gameState: Int {
        return 3
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
    
    func determineRightMove() {
        guard let currentNode = self.gameTree?.currentNode else { return }
        self.rightMove = []
        let decoder = SanSerialization.default
        for node in currentNode.children {
            self.rightMove.append(decoder.move(for: node.move, in: self.game))
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
            print(game.legalMoves)
            return
        }
        self.moveHistory = Array(self.moveHistory.prefix(self.positionIndex+1))
        self.positionHistory = Array(self.positionHistory.prefix(self.positionIndex+1))
        makeMove(move)
        
    }
    
    func makeMove(_ move: Move) {
        guard let gameTree = self.gameTree else { return }
        let (success, newNode) = gameTree.currentNode!.databaseContains(move: move, in: self.game)
        
        if success {
            gameTree.currentNode = newNode
            let moveString = SanSerialization.default.san(for: move, in: self.game)
            self.moveStringList.append(moveString)
            
            if self.positionIndex + 1 != self.positionHistory.count {
                self.positionHistory = Array(self.positionHistory.prefix(self.positionIndex+1))
            }
            self.positionHistory.append(self.game.position)
            self.moveHistory.append((move, moveString))
            self.positionIndex = self.positionIndex + 1
            
            
            self.game.make(move: move)
            gameTree.gameState = 0
            determineRightMove()
            objectWillChange.send()
        } else {
//            gameTree.gameCopy = self.game.deepCopy()
//            if !gameTree.currentNode!.children.isEmpty {
//                gameTree.gameState = 1
//
////                determineRightMove()
//                game.make(move: move)
//
//            } else {
//                print("Hä")
//                gameTree.gameState = 2
//            }
//            objectWillChange.send()
        }
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
    }
    
    func makeMainLineMove() {
        let decoder = SanSerialization.default
        
        guard let moveString = gameTree?.currentNode?.children.first?.move else {return}
        let move = decoder.move(for: moveString, in: self.game)
        self.makeMove(move)
    }
    
    func forwardMove() {
        guard let gameTree = self.gameTree else {return}
        if self.positionIndex + 1 != self.positionHistory.count {
            self.positionIndex += 1
            
            let moveString = self.moveHistory[positionIndex].1
            gameTree.currentNode = gameTree.currentNode?.children.first(where: {$0.move == moveString})
            
            self.game.make(move: self.moveHistory[positionIndex].0)
            
            determineRightMove()
            objectWillChange.send()
        } else {
            makeMainLineMove()
        }
    }
    
    func reverseMove() {
        guard self.positionIndex >= 0 else {return}
        guard let gameTree = self.gameTree else {return}
        
        self.game = Game(position: positionHistory[positionIndex], moves: Array(self.game.movesHistory.prefix(positionIndex)))
        self.positionIndex -= 1
        print()
        
        gameTree.currentNode = gameTree.currentNode?.parent
        determineRightMove()
        objectWillChange.send()
    }
    
    func onAppear(database: DataBase) {
        if database.gametrees.isEmpty {
            self.resetGameTree()
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
    
    func resetGameTree(to newGameTree: GameTree? = nil) {
        self.moveStringList = []
        self.game = Game(position: startingGamePosition)
        
        self.moveHistory = []
        self.positionHistory = []
        self.positionIndex = -1
        self.promotionMove = nil
        self.rightMove = []
        
        if let newGameTree = newGameTree {
            newGameTree.lastPlayed = Date()
            newGameTree.reset()
            self.gameTree = newGameTree
        } else {
            guard let gameTree = self.gameTree else { return }
            gameTree.reset()
        }
        objectWillChange.send()
    }
}
