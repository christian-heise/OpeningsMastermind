//
//  ChessboardViewNew.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI
import ChessKit

struct ChessboardView<ParentVM>: View where ParentVM: ParentChessBoardModelProtocol {
    @ObservedObject private var settings: Settings
    
    @StateObject private var vm: ChessBoardViewModel<ParentVM>
    @ObservedObject private var parentVM: ParentVM
    
    @State var dragOffset: CGSize = .zero
    
    init(vm vm_parent: ParentVM, settings: Settings) where ParentVM: ParentChessBoardModelProtocol {
        self._vm = StateObject(wrappedValue: ChessBoardViewModel(vm_practiceView: vm_parent))
        self.settings = settings
        self.parentVM = vm_parent
    }
    
    let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) { row in
                    ForEach(0..<8) { col in
                        Group {
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? settings.boardColorRGB.white.getColor() : settings.boardColorRGB.black.getColor())
                                .frame(width: vm.squareLength(in: geo.size), height: vm.squareLength(in: geo.size))
                                .position(vm.squarePosition(in: geo.size, col: col, row: row))
                                
                            if let piece = vm.pieces.first(where: {$0.0 == Square(file: col, rank: 7-row)}) {
                                Image.piece(color: piece.1.color, kind: piece.1.kind)
                                    .resizable()
                                    .frame(width: vm.squareLength(in: geo.size),height:vm.squareLength(in: geo.size))
                                    .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                                    .position(x: geo.size.width/2 + (CGFloat(piece.0.file) - 3.5) * vm.squareLength(in: geo.size), y:vm.squareLength(in: geo.size)*4 - (CGFloat(piece.0.rank) - 3.5) * vm.squareLength(in: geo.size))
                                    .offset(piece.0 == vm.draggedSquare ? dragOffset : .zero)
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged{ value in
                                                if value.startLocation == value.location {
                                                    parentVM.selectedSquare = nil
                                                }
                                                vm.draggedSquare = piece.0
//                                                vm.offsets[vm.indexOf(piece.0)] = value.translation
                                                dragOffset = value.translation
                                            }
                                            .onEnded { value in
                                                vm.draggedSquare = nil
                                                vm.dragEnded(at: value, piece: piece.1, square: piece.0, in: geo.size)
                                            })
                                    .zIndex(vm.draggedSquare==piece.0 ? 1000:10)
                            }
                            if let lastMove = vm.last2Moves.0 {
                                if lastMove.to == Square(file: col, rank: 7-row) || lastMove.from == Square(file: col, rank: 7-row) {
                                    Rectangle()
                                        .fill(vm.gameState == 1 ? Color.red : Color.yellow)
                                        .frame(width: vm.squareLength(in: geo.size), height: vm.squareLength(in: geo.size))
                                        .position(vm.squarePosition(in: geo.size, col: col, row: row))
                                        .opacity(0.2)
                                }
                            }
                            if row == (vm.userColor == .white ? 7 : 0) {
                                Text(files[col])
                                    .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                                    .position(vm.indicatorPosition(in: geo.size, col: col, row: row))
                                    .offset(vm.indicatorOffset(in: geo.size, rowIndicator: false))
                                    .font(.system(size: vm.squareLength(in: geo.size)/4))
                                    .foregroundColor((row + col) % 2 == 0 ? settings.boardColorRGB.black.getColor() : settings.boardColorRGB.white.getColor())
                            }
                            if col == (vm.userColor == .white ? 0 : 7) {
                                Text(String(8-row))
                                    .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                                    .position(vm.indicatorPosition(in: geo.size, col: col, row: row))
                                    .offset(vm.indicatorOffset(in: geo.size, rowIndicator: true))
                                    .font(.system(size: vm.squareLength(in: geo.size)/4))
                                    .foregroundColor((row + col) % 2 == 0 ? settings.boardColorRGB.black.getColor() : settings.boardColorRGB.white.getColor())
                            }
                            Circle()
                                .opacity(vm.possibleSquares.contains(Square(file: col, rank: 7-row)) ? 0.3 : 0.0)
                                .frame(width: vm.squareLength(in: geo.size)/2)
                                .position(vm.squarePosition(in: geo.size, col: col, row: row))
                            
                            if vm.selectedSquare?.0 == Square(file: col, rank: 7-row) {
                                Rectangle()
                                    .fill(Color.yellow)
                                    .opacity(0.6)
                                    .frame(width: vm.squareLength(in: geo.size), height: vm.squareLength(in: geo.size))
                                    .reverseMask({
                                        Rectangle()
                                            .frame(width: vm.squareLength(in: geo.size)-10, height: vm.squareLength(in: geo.size)-10)
                                    })
                                    .position(vm.squarePosition(in: geo.size, col: col, row: row))
                            }
                        }
                        .onTapGesture {
                            if let selectedSquare = vm.selectedSquare {
                                if parentVM.game.legalMoves.contains(where: {$0.from == Square(file: col, rank: 7-row)}) {
                                    vm.selectedSquare = vm.pieces.first(where: {$0.0 == Square(file: col, rank: 7-row)})
                                } else {
                                    parentVM.processMoveAction(piece: selectedSquare.1, from: selectedSquare.0, to: Square(file: col, rank: 7-row))
                                    vm.selectedSquare = nil
                                }
                            } else if let piece = vm.pieces.first(where: {$0.0 == Square(file: col, rank: 7-row)}) {
                                if parentVM.game.legalMoves.contains(where: {$0.from == Square(file: col, rank: 7-row)}) {
                                    vm.selectedSquare = piece
                                }
                            }
                        }
                    }
                }
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 8 * vm.squareLength(in: geo.size), height: 8 * vm.squareLength(in: geo.size))
                    .position(x: geo.size.width/2,y: 4 * vm.squareLength(in: geo.size))
                
                if vm.gameState == 1 || vm.gameState == 4 {
                    ForEach(vm.rightMove, id: \.self) { rightMove in
                        ArrowShape()
                            .frame(width: vm.calcArrowWidth(for: rightMove, in: geo.size), height: vm.squareLength(in: geo.size)*0.6)
                            .rotationEffect(.degrees(vm.calcArrowAngleDeg(for: rightMove, in: geo.size)))
                            .position(vm.calcArrowPosition(for: rightMove, in: geo.size))
                            .opacity(0.7)
                            .foregroundColor(.green)
                            .zIndex(50)
                    }
                }
                if let move = vm.last2Moves.0, let annotation = vm.annotations.0 {
                    AnnotationView(annotation: annotation)
                        .frame(width: vm.squareLength(in: geo.size)*0.5)
                        .position(vm.positionAnnotation(move.to, in: geo.size))
                        .zIndex(500)
                }
                if let move = vm.last2Moves.1, let annotation = vm.annotations.1 {
                    AnnotationView(annotation: annotation)
                        .frame(width: vm.squareLength(in: geo.size)*0.5)
                        .position(vm.positionAnnotation(move.to, in: geo.size))
                        .zIndex(500)
                }
                if let move = vm.promotionMove {
                    PawnPromotionView(color: vm.userColor, width: vm.squareLength(in: geo.size)*1.2, parentVM: parentVM)
                        .position(vm.positionPawnPromotionView(move.to, in: geo.size))
                        .zIndex(1000)
                }
            }
        }
    }
}

struct ChessboardView_Previews: PreviewProvider {
    static var previews: some View {
        ChessboardView(vm: PracticeViewModel(database: DataBase()), settings: Settings())
    }
}
