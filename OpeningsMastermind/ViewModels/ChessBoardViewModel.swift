//
//  ChessBoardViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 10.05.23.
//

import Foundation
import ChessKit
import SwiftUI

extension ChessboardView {
    @MainActor class ChessBoardViewModel<ParentVM: ParentChessBoardModelProtocol>: ObservableObject {
        var vm_parent: ParentVM
        
        @Published var offsets = Array(repeating: CGSize.zero, count: 64)
        @Published var draggedSquare: Square? = nil
        
        init(vm_practiceView: ParentVM) {
            self.vm_parent = vm_practiceView
        }
        
        var annotations: (String?, String?) {
            var annotations = vm_parent.annotation
            if vm_parent.gameState == 1 { return (nil,nil)}
            if annotations.0 == "" {
                annotations.0 = nil
            }
            if annotations.1 == "" {
                annotations.1 = nil
            }
            
            if vm_parent.last2Moves.0?.to == vm_parent.last2Moves.1?.to {
                annotations.1 = nil
            }
            return annotations
        }
        
        var selectedSquare: (Square, Piece)?  {
            get {
                return vm_parent.selectedSquare
            }
            set {
                vm_parent.selectedSquare = newValue
            }
        }
        
        var last2Moves: (Move?,Move?) {
            vm_parent.last2Moves
        }
        
        var gameState: Int {
            vm_parent.gameState
        }
        
        var userColor: PieceColor {
            vm_parent.userColor
        }
        
        var rightMove: [Move] {
            vm_parent.rightMove
        }
        
        var pieces: [(Square, Piece)] {
            return vm_parent.pieces
        }
        
        var promotionMove: Move? {
            vm_parent.promotionMove
        }
        
        @Published var possibleSquares: [Square] = []
        
        func getPossibleSquares() {
            if let selectedSquare = self.selectedSquare?.0 {
                self.possibleSquares = vm_parent.game.legalMoves.filter({$0.from == selectedSquare}).map({$0.to})
            } else if let draggedSquare = self.draggedSquare {
                self.possibleSquares = vm_parent.game.legalMoves.filter({$0.from == draggedSquare}).map({$0.to})
            } else {
                self.possibleSquares = []
            }
        }
        
        func indicatorPosition(in size: CGSize, col: Int, row: Int) -> CGPoint {
            return CGPoint(x: size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: size), y: ((CGFloat(row) + 0.5) * squareLength(in: size)))
        }
        
        func indicatorOffset(in size: CGSize, rowIndicator: Bool) -> CGSize {
            if rowIndicator {
                return CGSize(width: (vm_parent.userColor == .white ? -0.4 : 0.4)*squareLength(in: size), height: (vm_parent.userColor == .white ? -0.35 : 0.35)*squareLength(in: size))
            } else {
                return CGSize(width: (vm_parent.userColor == .white ? 0.4 : -0.4)*squareLength(in: size), height: (vm_parent.userColor == .white ? 0.35 : -0.35)*squareLength(in: size))
            }
        }
        
        func squarePosition(in size: CGSize, col: Int, row: Int) -> CGPoint {
            return CGPoint(x: size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: size), y: (CGFloat(row) + 0.5) * squareLength(in: size))
        }
        
        func dragEnded(at value: DragGesture.Value, piece: Piece, square: Square, in size: CGSize) {
            self.offsets[indexOf(square)] = .zero
            let newSquare = squareOf(value.location, in: size)
            vm_parent.processMoveAction(piece: piece, from: square, to: newSquare)
        }
        
        func squareLength(in size: CGSize) -> CGFloat {
            return min(size.width, size.height) / 8
        }
        
        func indexOf(_ square: Square) -> Int {
            return square.file + square.rank * 8
        }
        
        func squareOf(_ point: CGPoint, in size: CGSize) -> Square {
            let file = min(max(Int(4 - (size.width/2 - point.x)/squareLength(in: size)), 0), 7)
            let rank = min(max(Int(8*(1 - point.y / squareLength(in: size)/8)), 0), 7)
            return Square(file: file, rank: rank)
        }
        
        func pointOf(_ square: Square, in size: CGSize) -> CGPoint {
            let x = size.width/2 + (CGFloat(square.file) - 3.5) * squareLength(in: size)
            let y = squareLength(in: size)*4 - (CGFloat(square.rank) - 3.5) * squareLength(in: size)
            return CGPoint(x: x, y: y)
        }
        
        func calcArrowPosition(for move: Move, in size: CGSize) -> CGPoint {
            let x = (pointOf(move.from, in: size).x + pointOf(move.to, in: size).x) / 2
            let y = (pointOf(move.from, in: size).y + pointOf(move.to, in: size).y) / 2
            
            return CGPoint(x: x, y: y)
        }
        func calcArrowWidth(for move: Move, in size: CGSize) -> CGFloat {
            return sqrt(pow(pointOf(move.from, in: size).x - pointOf(move.to, in: size).x, 2) + pow(pointOf(move.from, in: size).y - pointOf(move.to, in: size).y, 2))
        }
        
        func calcArrowAngleDeg(for move: Move, in size: CGSize) -> Double {
            let xdiff = pointOf(move.to, in: size).x - pointOf(move.from, in: size).x
            let ydiff = pointOf(move.to, in: size).y - pointOf(move.from, in: size).y
            return atan2(ydiff,xdiff) * 180 / Double.pi
        }
        
        func positionAnnotation(_ square: Square, in size: CGSize) -> CGPoint {
            let point_square = pointOf(square, in: size)
            
            return CGPoint(x:point_square.x + squareLength(in: size)*0.35, y:point_square.y + 3.35*squareLength(in: size))
        }
        func positionPawnPromotionView(_ square: Square, in size: CGSize) -> CGPoint {
            let point_square = pointOf(square, in: size)
            let xPoint = max(min(point_square.x, size.width - 2.4*squareLength(in: size) - 20), 2.4*squareLength(in: size) + 20)
            return CGPoint(x: xPoint, y: point_square.y + 1.3*squareLength(in: size))
        }
    }
}
