//
//  ChessBoardView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.04.23.
//

import ChessKit
import SwiftUI

let italianGameFen = "r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
let italianGamePosition = FenSerialization.default.deserialize(fen: italianGameFen)

struct ChessBoardView: View {
    @Binding var game: Game
    @Binding var currentNode: GameNode?
//    {
//        didSet {
//            self.currentNode = self.rootNode
//            print("currentNode should be set")
//        }
//    }
    
//    @State private var currentNode: GameNode?
    
    @State private var offsets = Array(repeating: CGSize.zero, count: 64)
    @State private var draggedSquare: Square? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) {row in
                    ForEach(0..<8) {col in
                        Rectangle()
                        .fill((row + col) % 2 == 0 ? Color.white : Color.brown)
                        .frame(width: squareLength(in: geo.size), height: squareLength(in: geo.size))
                        .position(x: (CGFloat(col) + 0.5) * squareLength(in: geo.size), y: (CGFloat(row) + 0.5) * squareLength(in: geo.size))
                    }
                }
                
            }
            .frame(width: squareLength(in: geo.size)*8, height: squareLength(in: geo.size)*8)
            .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 1)
            )
            
            ZStack {
                let pieces = game.position.board.enumeratedPieces()
                ForEach(pieces, id: \.0) { piece in
                    Image(imageNames[piece.1.color]?[piece.1.kind] ?? "")
                        .scaleEffect(0.8)
                        .position(x: squareLength(in: geo.size) * (CGFloat(piece.0.file) + 0.5), y: squareLength(in: geo.size) * (8 - CGFloat(piece.0.rank) - 0.5))
                        .offset(offsets[indexFromSquare(piece.0)])
                        .gesture(
                        DragGesture()
                            .onChanged { value in
                                self.draggedSquare = piece.0
                                self.offsets[indexFromSquare(piece.0)] = value.translation
                            }
                            .onEnded { value in
                                self.draggedSquare = nil
                                if piece.1.color == .white {
                                    let newSquare = squareFromPoint(value.location, in: geo.size)
                                    if newSquare != piece.0 {
                                        let move = Move(from: piece.0, to: newSquare)
                                        if game.legalMoves.contains(move) {
                                            let tupel = currentNode!.databaseContains(move: move, in: game)
                                            currentNode = tupel.1
                                            if tupel.0 {
                                                print("Move is in Database")
                                                game.make(move: move)
                                                currentNode = makeBlackMove()
                                            } else {
                                                print("Move is NOT in Database")
                                                game.make(move: move)
                                            }
                                        }
                                    }
                                }
                                self.offsets[indexFromSquare(piece.0)] = .zero
                            }
                        )
                        .disabled(currentNode == nil)
                        .zIndex(self.draggedSquare==piece.0 ? 1000:0)
                }
            }
        }
        .padding()
    }
    
    func indexFromSquare(_ square: Square) -> Int {
        return square.file + square.rank * 8
    }
    
    func squareFromPoint(_ point: CGPoint, in size: CGSize) -> Square {
        let file = min(max(Int(point.x / (size.width / 8)), 0), 7)
        let rank = min(max(Int(8*(1 - point.y / size.width)), 0), 7)
        return Square(file: file, rank: rank)
    }
    
    func squareLength(in size: CGSize) -> CGFloat {
        return min(size.width, size.height) / 8
    }
    
    func makeBlackMove() -> GameNode {
        if currentNode!.children.isEmpty {
            return currentNode!
        }
        let tupel = currentNode!.generateMove(game: game)
        self.game.make(move: tupel.0)
        return tupel.1
    }
}

let imageNames: [PieceColor: [PieceKind: String]] = [
    .white: [
        .king: "Chess_klt60",
        .queen: "Chess_qlt60",
        .bishop: "Chess_blt60",
        .knight: "Chess_nlt60",
        .rook: "Chess_rlt60",
        .pawn: "Chess_plt60"
    ],
    .black: [
        .king: "Chess_kdt60",
        .queen: "Chess_qdt60",
        .bishop: "Chess_bdt60",
        .knight: "Chess_ndt60",
        .rook: "Chess_rdt60",
        .pawn: "Chess_pdt60"
    ]
]

struct ChessBoardView_Previews: PreviewProvider {
    
    static var previews: some View {
        ChessBoardView(game: .constant(Game(position: italianGamePosition)), currentNode: .constant(nil))
    }
}
