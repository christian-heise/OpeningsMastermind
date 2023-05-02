//
//  examplePGN.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 23.04.23.
//

import Foundation
import ChessKit

struct ExamplePGN: Hashable {
//    static let exampleGameTrees = [GameTree(name: "Smith Morra Gambit", pgnString: examplePGNSmithMorra, userColor: .white),
//                            GameTree(name: "Scotch Gambit", pgnString: examplePGNScotchGambit, userColor: .white),
//                            GameTree(name: "Danish Gambit Refutation", pgnString: examplePGNDanishRefutation, userColor: .black),
//                            GameTree(name: "Englund Gambit Refuntation", pgnString: examplePGNEnglundRefutation, userColor: .white),
//                            GameTree(name: "Caro Kann Goldman Variation", pgnString: examplePGNCaroKannGoldMan, userColor: .white)]
    
    let gameTree: GameTree?
    var isChecked = true
    let id = UUID()
    
    init(name: String, userColor: PieceColor, fileName: String) {
        if let startWordsURL = Bundle.main.url(forResource: fileName, withExtension: "pgn") {
            if let pgnString = try? String(contentsOf: startWordsURL) {
                self.gameTree = GameTree(name: name, pgnString: pgnString, userColor: userColor)
            } else {
                self.gameTree = nil
            }
        } else {
            self.gameTree = nil
        }
    }
    
    static let list = [ExamplePGN(name: "Caro Kann Goldman Variation", userColor: .white, fileName: "exampleCaroKannGoldman"),
                       ExamplePGN(name: "Danish Gambit Refutation", userColor: .black, fileName: "exampleDanishRefutation"),
                       ExamplePGN(name: "Scotch Gambit", userColor: .white, fileName: "exampleScotchGambit"),
                       ExamplePGN(name: "Smith Morra Gambit", userColor: .white, fileName: "exampleSmithMorra"),
                       ExamplePGN(name: "Englund Gambit Refutation", userColor: .white, fileName: "exampleEnglundRefutation")].sorted(by: {$0.gameTree!.name < $1.gameTree!.name})
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func ==(lhs: ExamplePGN, rhs: ExamplePGN) -> Bool {
        return lhs.id == rhs.id
    }
}


