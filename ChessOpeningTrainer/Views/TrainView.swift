//
//  TrainView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 21.04.23.
//

import SwiftUI
import ChessKit

struct TrainView: View {
    @State var game = Game(position: startingGamePosition)
    @StateObject var gameTree: GameTree
    @State private var gameState = 0
    
    let settings: Settings

    var body: some View {
        NavigationView {
            VStack {
                GeometryReader { geo in
                    ChessBoardView(game: $game, gameTree: gameTree, settings: settings)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .rotationEffect(.degrees(gameTree.userColor == .white ? 0 : 180))
                }
                    .navigationTitle(Text("Training"))
                if gameTree.gameState == 1 {
                    Text("This was the wrong move!")
                } else if gameTree.gameState == 2 {
                    Text("This was the last move in this Study")
                }
                if gameTree.gameState > 0 {
                    Button("Restart", action: {
                        self.game = Game(position: startingGamePosition)
                        self.gameTree.reset()
                        if gameTree.userColor == .black {
                            makeNextMove()
                        }
                        print("Reset complete")
                    })
                }
                Spacer()
                Text("Remaining max depth of current line: " + String(gameTree.currentNode!.depth))
            }
        }
        .onAppear() {
            self.game = Game(position: startingGamePosition)
        }
        .onDisappear() {
            self.gameTree.reset()
        }
//        .toolbar(.hidden, for: .tabBar)
    }
    
    func makeNextMove() {
        if self.gameTree.currentNode!.children.isEmpty {
            self.gameTree.gameState = 2
            return
        }
        let (newMove, newNode) = self.gameTree.generateMove(game: game)
        
        self.game.make(move: newMove!)
        if newNode!.children.isEmpty {
            self.gameTree.gameState = 2
        }
        self.gameTree.currentNode = newNode!
    }
}

struct TrainView_Previews: PreviewProvider {
    static var previews: some View {
        TrainView(gameTree: GameTree.example(), settings: Settings())
    }
}
