//
//  examplePGN.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 23.04.23.
//

import Foundation
import ChessKit

struct ExamplePGN: Hashable {
    
    let pgnString: String?
    let userColor: PieceColor
    let name: String
    let creator: String
    var isChecked = true
    let id = UUID()
    let url: String
    
    init(name: String, userColor: PieceColor, fileName: String, creator: String, url: String) {
        self.creator = creator
        self.url = url
        
        self.name = name
        self.userColor = userColor
        
        if let startWordsURL = Bundle.main.url(forResource: fileName, withExtension: "pgn") {
            if let pgnString = try? String(contentsOf: startWordsURL) {
                self.pgnString = pgnString
            } else {
                self.pgnString = nil
            }
        } else {
            self.pgnString = nil
        }
    }
    
    static let list = [ExamplePGN(name: "Caro Kann Goldman Variation", userColor: .white, fileName: "exampleCaroKannGoldman", creator: "xJimmyCx on Lichess.com", url: "https://lichess.org/study/Rvu7G9VX"),
                       ExamplePGN(name: "Danish Gambit Refutation", userColor: .black, fileName: "exampleDanishRefutation", creator: "RebeccaHarris on Lichess.com", url: "https://lichess.org/study/udExyu0p"),
                       ExamplePGN(name: "Scotch Gambit", userColor: .white, fileName: "exampleScotchGambit", creator: "tgood on Lichess.com", url: "https://lichess.org/study/d05kyFwr"),
                       ExamplePGN(name: "Smith Morra Gambit", userColor: .white, fileName: "exampleSmithMorra", creator: "yooloo, mineriva, ThatRaisinTho on Lichess.com", url: "https://lichess.org/study/ccnOaWVC"),
                       ExamplePGN(name: "Englund Gambit Refutation", userColor: .white, fileName: "exampleEnglundRefutation", creator: "RebeccaHarris on Lichess.com", url: "https://lichess.org/study/inBWS4oN")].sorted(by: {$0.name < $1.name})
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: ExamplePGN, rhs: ExamplePGN) -> Bool {
        return lhs.id == rhs.id
    }
}


