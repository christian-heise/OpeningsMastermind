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
    var body: some View {
        VStack {
            CreateStudyView()

        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
