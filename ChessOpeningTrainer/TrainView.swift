//
//  TrainView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 21.04.23.
//

import SwiftUI
import ChessKit

struct TrainView: View {
    @State private var game = Game(position: startingGamePosition)
    let gameTree: GameTree

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct TrainView_Previews: PreviewProvider {
    static var previews: some View {
        TrainView(gameTree: GameTree.example())
    }
}
