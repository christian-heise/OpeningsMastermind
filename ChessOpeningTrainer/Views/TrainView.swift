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
                        .padding(.bottom, 20)
                } else if gameTree.gameState == 2 {
                    Text("This was the last move in this Study")
                        .padding(.bottom, 20)
                }
                    
                HStack {
                    if gameTree.gameState == 1 {
                        Button(action: {
                            self.game = gameTree.gameCopy ?? Game(position: startingGamePosition)
                            gameTree.gameState = 0
                            print("Should have reversed")
                        }) {
                            Text("Revert Last Move")
                                .padding()
                                .foregroundColor(.white)
//                                .background([217,83,79].getColor())
                                .background([223,110,107].getColor())
                                .cornerRadius(10)
                        }
                    }
                    if gameTree.gameState > 0 {
                        Button(action: {
                            self.game = Game(position: startingGamePosition)
                            self.gameTree.reset()
                            if gameTree.userColor == .black {
                                makeNextMove()
                            }
                            print("Reset complete")
                        }) {
                            Text("Restart Training")
                                .padding()
                                .foregroundColor(.white)
                                .background([79,147,206].getColor())
                                .cornerRadius(10)
                        }
                    }
                }
                Spacer()
//                Text("Remaining max depth of current line: " + String(gameTree.currentNode!.depth))
//                Text("Misstakes in the line: " + String(gameTree.currentNode!.misstakesSum))
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
