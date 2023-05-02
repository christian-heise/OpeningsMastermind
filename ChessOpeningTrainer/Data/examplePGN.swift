//
//  examplePGN.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 23.04.23.
//

import Foundation
import ChessKit

struct ExamplePGN: Hashable {
    
    let gameTree: GameTree?
    let creator: String
    var isChecked = true
    let id = UUID()
    
    init(name: String, userColor: PieceColor, fileName: String, creator: String) {
        self.creator = creator
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
    
    static let list = [ExamplePGN(name: "Caro Kann Goldman Variation", userColor: .white, fileName: "exampleCaroKannGoldman", creator: "xJimmyCx on Lichess.com"),
                       ExamplePGN(name: "Danish Gambit Refutation", userColor: .black, fileName: "exampleDanishRefutation", creator: "RebeccaHarris on Lichess.com"),
                       ExamplePGN(name: "Scotch Gambit", userColor: .white, fileName: "exampleScotchGambit", creator: "tgood on Lichess.com"),
                       ExamplePGN(name: "Smith Morra Gambit", userColor: .white, fileName: "exampleSmithMorra", creator: "yooloo, mineriva, ThatRaisinTho on Lichess.com"),
                       ExamplePGN(name: "Englund Gambit Refutation", userColor: .white, fileName: "exampleEnglundRefutation", creator: "RebeccaHarris on Lichess.com")].sorted(by: {$0.gameTree!.name < $1.gameTree!.name})
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func ==(lhs: ExamplePGN, rhs: ExamplePGN) -> Bool {
        return lhs.id == rhs.id
    }
}


