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
    @ObservedObject var gameTree: GameTree
    let settings: Settings
    
    @ObservedObject var database: DataBase
    
    @State private var offsets = Array(repeating: CGSize.zero, count: 64)
    @State private var draggedSquare: Square? = nil
    
    var movingDisabled: Bool {
        if self.gameTree.gameState > 0 {
            return true
        }
        return false
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) {row in
                    ForEach(0..<8) {col in
                        Rectangle()
                            .fill((row + col) % 2 == 0 ? settings.boardColorRGB.white.getColor() : settings.boardColorRGB.black.getColor())
                            .frame(width: squareLength(in: geo.size), height: squareLength(in: geo.size))
                            .position(x: geo.size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: geo.size), y: (CGFloat(row) + 0.5) * squareLength(in: geo.size))
                        if let lastMove = game.movesHistory.last {
                            if lastMove.to == Square(file: col, rank: 7-row) || lastMove.from == Square(file: col, rank: 7-row) {
                                Rectangle()
                                    .fill(gameTree.gameState == 1 ? Color.red : Color.yellow)
                                    .frame(width: squareLength(in: geo.size), height: squareLength(in: geo.size))
                                    .position(x: geo.size.width/2 + (CGFloat(col) - 3.5) * squareLength(in: geo.size), y: ((CGFloat(row) + 0.5) * squareLength(in: geo.size)))
                                    .opacity(0.2)
                            }
                        }
                    }
                }
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 8 * squareLength(in: geo.size), height: 8 * squareLength(in: geo.size))
                    .position(x: geo.size.width/2,y: 4 * squareLength(in: geo.size))
                if gameTree.gameState == 1 {
                    if let rightMove = self.gameTree.rightMove {
                        ArrowShape()
                            .frame(width: calcArrowWidth(for: rightMove, in: geo.size), height: squareLength(in: geo.size)*0.6)
                            .rotationEffect(.degrees(calcArrowAngleDeg(for: rightMove, in: geo.size)))
                            .position(calcArrowPosition(for: rightMove, in: geo.size))
                            .opacity(0.7)
                            .foregroundColor(.green)
                            .zIndex(50)
                    }
                }

                let pieces = game.position.board.enumeratedPieces()
                ForEach(pieces, id: \.0) { piece in
                    Image(imageNames[piece.1.color]?[piece.1.kind] ?? "")
                        .resizable()
                        .frame(width: squareLength(in: geo.size),height: squareLength(in: geo.size))
                        .rotationEffect(.degrees(gameTree.userColor == .white ? 0 : 180))
                        .position(x: geo.size.width/2 + (CGFloat(piece.0.file) - 3.5) * squareLength(in: geo.size), y: squareLength(in: geo.size)*4 - (CGFloat(piece.0.rank) - 3.5) * squareLength(in: geo.size))
                        .offset(offsets[indexFromSquare(piece.0)])
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    self.draggedSquare = piece.0
                                    self.offsets[indexFromSquare(piece.0)] = value.translation
                                }
                                .onEnded { value in
                                    self.draggedSquare = nil
                                    if piece.1.color == gameTree.userColor {
                                        let newSquare = squareFromPoint(value.location, in: geo.size)
                                        if newSquare != piece.0 {
                                            let move = Move(from: piece.0, to: newSquare)
                                            print(game.legalMoves)
                                            if game.legalMoves.contains(move) {
                                                if let tupel = gameTree.currentNode?.databaseContains(move: move, in: game) {
                                                    if gameTree.currentNode!.mistakesLast10Moves.count == 10 {
                                                        gameTree.currentNode!.mistakesLast10Moves.removeFirst()
                                                    }
                                                    if tupel.0 {
                                                        gameTree.currentNode!.mistakesLast10Moves.append(0)
                                                        database.save()
                                                        gameTree.currentNode = tupel.1
                                                        print("Move is in Database")
                                                        game.make(move: move)
                                                        Task {
                                                            await makeNextMove()
                                                        }
                                                    } else {
                                                        print("Move is NOT in Database")
                                                        gameTree.gameCopy = self.game.deepCopy()
                                                        if !gameTree.currentNode!.children.isEmpty {
                                                            gameTree.currentNode!.mistakesLast10Moves.append(1)
                                                            self.gameTree.gameState = 1
                                                            database.save()
                                                            self.gameTree.rightMove = determineRightMove()
                                                        }
                                                        game.make(move: move)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    self.offsets[indexFromSquare(piece.0)] = .zero
                                }
                        )
                        .disabled(movingDisabled)
                        .zIndex(self.draggedSquare==piece.0 ? 1000:0)
                }
            }
            ZStack {
                if let currentNode = gameTree.currentNode {
                    if gameTree.gameState != 1 {
                        if let annotation_current = currentNode.annotation {
                            if annotation_current != "" {
                                AnnotationView(annotation: annotation_current)
                                    .frame(width: squareLength(in: geo.size)*0.5)
                                    .position(positionAnnotation(game.movesHistory.last!.to, in: geo.size))
                            }
                            
                        }
                    }
                    if let parent = currentNode.parent {
                        if game.movesHistory.suffix(2).first!.to != game.movesHistory.last!.to {
                            if let annotation_last = parent.annotation {
                                if annotation_last != "" {
                                    AnnotationView(annotation: annotation_last)
                                        .frame(width: squareLength(in: geo.size)*0.5)
                                        .position(positionAnnotation(game.movesHistory.suffix(2).first!.to, in: geo.size))
                                }
                            }
                        }
                    }
                }
            }
        }

    }
    
    func positionAnnotation(_ square: Square, in size: CGSize) -> CGPoint {
        let point_square = pointFromSquare(square, in: size)
        
//        return CGPoint(x:point_square.x + squareLength(in: size)*0.35, y:point_square.y - squareLength(in: size)*0.35)
        return CGPoint(x:point_square.x + squareLength(in: size)*0.35, y:point_square.y + 3.35*squareLength(in: size))
    }
    
    func indexFromSquare(_ square: Square) -> Int {
        return square.file + square.rank * 8
    }
    
    func squareFromPoint(_ point: CGPoint, in size: CGSize) -> Square {
        let file = min(max(Int(4 - (size.width/2 - point.x)/squareLength(in: size)), 0), 7)
        let rank = min(max(Int(8*(1 - point.y / squareLength(in: size)/8)), 0), 7)
        print("file: "+String(file)+", rank: "+String(rank))
        return Square(file: file, rank: rank)
    }
    
    func pointFromSquare(_ square: Square, in size: CGSize) -> CGPoint {
        let x = size.width/2 + (CGFloat(square.file) - 3.5) * squareLength(in: size)
        let y = squareLength(in: size)*4 - (CGFloat(square.rank) - 3.5) * squareLength(in: size)
        return CGPoint(x: x, y: y)
    }
    
    func squareLength(in size: CGSize) -> CGFloat {
        return min(size.width, size.height) / 8
    }
    
    func makeNextMove() async {
        if self.gameTree.currentNode!.children.isEmpty {
            self.gameTree.gameState = 2
            return
        }
        let (newMove, newNode) = self.gameTree.generateMove(game: game)
        
        try? await Task.sleep(for: .milliseconds(300))
        self.game.make(move: newMove!)
        if newNode!.children.isEmpty {
            self.gameTree.gameState = 2
        }
        self.gameTree.currentNode = newNode!
    }
    
    func calcArrowPosition(for move: Move, in size: CGSize) -> CGPoint {
        let x = (pointFromSquare(move.from, in: size).x + pointFromSquare(move.to, in: size).x) / 2
        let y = (pointFromSquare(move.from, in: size).y + pointFromSquare(move.to, in: size).y) / 2
        
        return CGPoint(x: x, y: y)
    }
    func calcArrowWidth(for move: Move, in size: CGSize) -> CGFloat {
        return sqrt(pow(pointFromSquare(move.from, in: size).x - pointFromSquare(move.to, in: size).x, 2) + pow(pointFromSquare(move.from, in: size).y - pointFromSquare(move.to, in: size).y, 2))
    }
    
    func calcArrowAngleDeg(for move: Move, in size: CGSize) -> Double {
        let xdiff = pointFromSquare(move.to, in: size).x - pointFromSquare(move.from, in: size).x
        let ydiff = pointFromSquare(move.to, in: size).y - pointFromSquare(move.from, in: size).y
        return atan2(ydiff,xdiff) * 180 / Double.pi
    }
    
    func determineRightMove() -> Move {
        let decoder = SanSerialization.default
        let move = decoder.move(for: self.gameTree.currentNode!.children.first!.move, in: self.game)
        gameTree.currentNode = gameTree.currentNode!.children.first!
        return move
    }
}

let imageNames: [PieceColor: [PieceKind: String]] = [
    .white: [
        .king: "Chess_klt45.svg",
        .queen: "Chess_qlt45.svg",
        .bishop: "Chess_blt45.svg",
        .knight: "Chess_nlt45.svg",
        .rook: "Chess_rlt45.svg",
        .pawn: "Chess_plt45.svg"
    ],
    .black: [
        .king: "Chess_kdt45.svg",
        .queen: "Chess_qdt45.svg",
        .bishop: "Chess_bdt45.svg",
        .knight: "Chess_ndt45.svg",
        .rook: "Chess_rdt45.svg",
        .pawn: "Chess_pdt45.svg"
    ]
]

struct ChessBoardView_Previews: PreviewProvider {
    
    static var previews: some View {
        ChessBoardView(game: .constant(Game(position: italianGamePosition)), gameTree: GameTree.example(), settings: Settings(), database: DataBase())
    }
}
