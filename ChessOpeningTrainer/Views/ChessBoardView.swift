//
//  ChessboardViewNew.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI
import ChessKit

struct ChessboardView: View {
    @ObservedObject var settings: Settings
    @EnvironmentObject private var vm: PractiseViewModel
    
    @State private var offsets = Array(repeating: CGSize.zero, count: 64)
    @State private var draggedSquare: Square? = nil
    
    let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) {row in
                    ForEach(0..<8) {col in
                        Rectangle()
                            .fill((row + col) % 2 == 0 ? settings.boardColorRGB.white.getColor() : settings.boardColorRGB.black.getColor())
                            .frame(width: squareLength(in: geo.size), height: squareLength(in: geo.size))
                            .position(x: geo.size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: geo.size), y: (CGFloat(row) + 0.5) * squareLength(in: geo.size))
                        if let lastMove = vm.lastMove {
                            if lastMove.to == Square(file: col, rank: 7-row) || lastMove.from == Square(file: col, rank: 7-row) {
                                Rectangle()
                                    .fill(vm.gameState == 1 ? Color.red : Color.yellow)
                                    .frame(width: squareLength(in: geo.size), height: squareLength(in: geo.size))
                                    .position(x: geo.size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: geo.size), y: ((CGFloat(row) + 0.5) * squareLength(in: geo.size)))
                                    .opacity(0.2)
                            }
                        }
                        if row == (vm.userColor == .white ? 7 : 0) {
                            Text(files[col])
                                .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                                .position(x: geo.size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: geo.size), y: ((CGFloat(row) + 0.5) * squareLength(in: geo.size)))
                                .offset(x: (vm.userColor == .white ? 0.4 : -0.4)*squareLength(in: geo.size), y: (vm.userColor == .white ? 0.35 : -0.35)*squareLength(in: geo.size))
                                .font(.footnote)
                                .foregroundColor((row + col) % 2 == 0 ? settings.boardColorRGB.black.getColor() : settings.boardColorRGB.white.getColor())
                        }
                        if col == (vm.userColor == .white ? 0 : 7) {
                            Text(String(8-row))
                                .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                                .position(x: geo.size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: geo.size), y: ((CGFloat(row) + 0.5) * squareLength(in: geo.size)))
                                .offset(x: (vm.userColor == .white ? -0.4 : 0.4)*squareLength(in: geo.size), y: (vm.userColor == .white ? -0.35 : 0.35)*squareLength(in: geo.size))
                                .font(.footnote)
                                .foregroundColor((row + col) % 2 == 0 ? settings.boardColorRGB.black.getColor() : settings.boardColorRGB.white.getColor())
                        }
                    }
                }
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 8 * squareLength(in: geo.size), height: 8 * squareLength(in: geo.size))
                    .position(x: geo.size.width/2,y: 4 * squareLength(in: geo.size))
                
                if vm.gameState == 1 {
                    ForEach(vm.rightMove, id: \.self) { rightMove in
                        ArrowShape()
                            .frame(width: calcArrowWidth(for: rightMove, in: geo.size), height: squareLength(in: geo.size)*0.6)
                            .rotationEffect(.degrees(calcArrowAngleDeg(for: rightMove, in: geo.size)))
                            .position(calcArrowPosition(for: rightMove, in: geo.size))
                            .opacity(0.7)
                            .foregroundColor(.green)
                            .zIndex(50)
                    }
                }
                
                ForEach(vm.pieces, id: \.0) { piece in
                    Image.piece(color: piece.1.color, kind: piece.1.kind)
                        .resizable()
                        .frame(width: squareLength(in: geo.size),height: squareLength(in: geo.size))
                        .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        .position(x: geo.size.width/2 + (CGFloat(piece.0.file) - 3.5) * squareLength(in: geo.size), y: squareLength(in: geo.size)*4 - (CGFloat(piece.0.rank) - 3.5) * squareLength(in: geo.size))
                        .offset(offsets[indexOf(piece.0)])
                        .gesture(
                            DragGesture()
                                .onChanged{ value in
                                    self.draggedSquare = piece.0
                                    self.offsets[indexOf(piece.0)] = value.translation
                                }
                                .onEnded { value in
                                    self.draggedSquare = nil
                                    dragEnded(at: value, piece: piece.1, square: piece.0, in: geo.size)
                                })
                        .zIndex(self.draggedSquare==piece.0 ? 1000:10)
                }
                if let move = vm.last2Moves.0, let annotation = vm.annotation.0, annotation != "" && vm.gameState == 0 {
                    AnnotationView(annotation: annotation)
                        .frame(width: squareLength(in: geo.size)*0.5)
                        .position(positionAnnotation(move.to, in: geo.size))
                        .zIndex(500)
                }
                if let move = vm.last2Moves.1, let annotation = vm.annotation.1, annotation != "" && vm.gameState == 0 {
                    AnnotationView(annotation: annotation)
                        .frame(width: squareLength(in: geo.size)*0.5)
                        .position(positionAnnotation(move.to, in: geo.size))
                        .zIndex(500)
                }
                if let move = vm.promotionMove {
                    PawnPromotionView(color: vm.userColor, width: squareLength(in: geo.size)*1.2)
                        .position(positionPawnPromotionView(move.to, in: geo.size))
                        .zIndex(1000)
                }
            }
        }
    }
    
    func dragEnded(at value: DragGesture.Value, piece: Piece, square: Square, in size: CGSize) {
        self.offsets[indexOf(square)] = .zero
        let newSquare = squareOf(value.location, in: size)
        vm.processMove(piece: piece, from: square, to: newSquare)
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

struct ChessboardView_Previews: PreviewProvider {
    static let myEnvObject = PractiseViewModel()
    static var previews: some View {
        ChessboardView(settings: Settings())
            .environmentObject(myEnvObject)
    }
}
