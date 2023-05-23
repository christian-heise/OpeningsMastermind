//
//  LichessOpeningData.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.05.23.
//

import Foundation


struct LichessOpeningData: Codable {
    let white: Int
    let draws: Int
    let black: Int

    var moves: [LichessMove]

    let opening: Opening?

    struct Opening: Codable {
        let eco: String
        let name: String
    }
    struct LichessMove: Codable, Hashable {
        let uci: String
        let san: String
        let averageRating: Int
        let white: Int
        let draws: Int
        let black: Int
    }
    
    
    static let example = LichessOpeningData(white: 234, draws: 245, black: 253, moves: [LichessMove(uci: "sfs", san: "Nxd3", averageRating: 234, white: 425, draws: 535, black: 245), LichessMove(uci: "rsg", san: "exd4", averageRating: 2662, white: 465, draws: 236, black: 645),LichessMove(uci: "sfs", san: "Nxd3", averageRating: 234, white: 425, draws: 1, black: 245)], opening: nil)
}
