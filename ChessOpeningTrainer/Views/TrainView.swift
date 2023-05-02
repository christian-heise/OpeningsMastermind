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
    
    var text: String {
        if gameTree.gameState == 1 {
            return "This was the wrong move!"
        } else if gameTree.gameState == 2 {
            return "This was the last move in this Study"
        } else {
            return ""
        }
    }

    var body: some View {
        GeometryReader { geo in
            VStack() {
                Spacer()
                Spacer()
                ChessBoardView(game: $game, gameTree: gameTree, settings: settings)
                    .rotationEffect(.degrees(gameTree.userColor == .white ? 0 : 180))
                    .navigationTitle(Text("Training"))
                    .frame(maxHeight: geo.size.width)
                Spacer()
                Text(text)
                    .frame(height: 20)
                    .padding()
                    .opacity(gameTree.gameState > 0 ? 1 : 0)
                HStack {
                    Button(action: {
                        self.gameTree.currentNode = self.gameTree.currentNode!.parent
                        self.game = gameTree.gameCopy ?? Game(position: startingGamePosition)
                        gameTree.gameState = 0
                        print("Should have reversed")
                    }) {
                        Text("Revert Last Move")
                            .padding()
                            .foregroundColor(.white)
                        //                          .background([217,83,79].getColor())
                            .background([223,110,107].getColor())
                            .cornerRadius(10)
                    }
                    .opacity(gameTree.gameState == 1 ? 1 : 0)
                    .disabled(gameTree.gameState == 1 ? false : true)
                    
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
                    .opacity(gameTree.gameState > 0 ? 1 : 0)
                    .disabled(gameTree.gameState > 0 ? false : true)
                }
                .padding(10)
            }
        }
        .onAppear() {
            self.game = Game(position: startingGamePosition)
            self.gameTree.reset()
            if gameTree.userColor == .black {
                makeNextMove()
            }
            print("on Appear on Training view executed")
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
