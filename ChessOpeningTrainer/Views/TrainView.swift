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

    var body: some View {
        NavigationView {
            VStack {
                GeometryReader { geo in
                    ChessBoardView(game: $game, gameTree: gameTree)
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
                        print("Reset complete")
                    })
                }
                Spacer()
            }
        }
        .onAppear() {
            self.game = Game(position: startingGamePosition)
        }
        .onDisappear() {
            self.gameTree.reset()
        }
    }
}

struct TrainView_Previews: PreviewProvider {
    static var previews: some View {
        TrainView(gameTree: GameTree.example())
    }
}
