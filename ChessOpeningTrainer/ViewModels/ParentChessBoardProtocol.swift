//
//  ParentChessBoardProtocol.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import Foundation
import ChessKit

protocol ParentChessBoardModelProtocol: ObservableObject {
    var annotation: (String?, String?) { get }
    var gameState: Int { get }
    var last2Moves: (Move?, Move?) { get }
    var userColor: PieceColor { get }
    var rightMove: [Move] { get }
    var pieces: [(Square, Piece)] { get }
    var promotionMove: Move? { get }
    var moveHistory: [(Move, String)] { get }
    var positionHistory: [Position] { get }
    var positionIndex: Int { get }
    
    func processMoveAction(piece: Piece, from oldSquare: Square, to newSquare: Square)
    func reset()
    func jump(to index: Int)
}

class ParentChessBoardModel {
    @Published var gameState: Int = 0
    
    var game: Game = Game(position: startingGamePosition)
    var rightMove: [Move] = []
    var promotionPending: Bool = false
    var promotionMove: Move? = nil
    
    var moveHistory: [(Move, String)] = []
    var positionHistory: [Position] = []
    var positionIndex: Int = -1

    var pieces: [(Square, Piece)] {
        return game.position.board.enumeratedPieces()
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
    
    func processMoveAction(piece: Piece, from oldSquare: Square, to newSquare: Square) {
        // Promotion Logic
        if piece.kind == .pawn {
            if newSquare.rank == 7 || newSquare.rank == 0 {
                let move = Move(from: oldSquare, to: newSquare, promotion: .queen)
                if game.legalMoves.contains(move) {
                    gameState = 3
                    self.promotionMove = move
//                    objectWillChange.send()
                    return
                }
            }
        }
        performMove(Move(from: oldSquare, to: newSquare))
    }
    
    func performMove(_ move: Move) {}
}
