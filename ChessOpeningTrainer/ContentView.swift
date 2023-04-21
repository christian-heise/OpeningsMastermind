//
//  ContentView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.04.23.
//

import SwiftUI
import ChessKit

let pgnString = "1. e3 f6 2. Nf3 e5  3.d3 "

struct ContentView: View {
//    let game = Game(position: startingGamePosition)
//    @State var text: String = ""
//    @State var moveDescription = ""
    var body: some View {
        VStack {
            CreateStudyView()
            
//            TextField("Enter move here", text: $text)
//            Text(moveDescription)
//            Button("Enter", action: {
//                let decoder = SanSerialization.default
//                let legalMoves = game.legalMoves.description
//                print(legalMoves)
//                self.moveDescription = decoder.move(for: text, in: game).description
//            })
            
            
        }
        .padding()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
