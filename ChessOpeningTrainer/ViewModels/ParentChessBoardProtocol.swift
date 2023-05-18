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
    
    func processMove(piece: Piece, from oldSquare: Square, to newSquare: Square)
    
    func resetGameTree(to newGameTree: GameTree?)
}
