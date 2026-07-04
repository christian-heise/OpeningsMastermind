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
    
    
    static let example = LichessOpeningData(
        white: 4_823_100,
        draws: 1_204_700,
        black: 4_119_200,
        moves: [
            LichessMove(uci: "e2e4", san: "e4",  averageRating: 1632, white: 2_410_500, draws: 621_300, black: 2_058_200),
            LichessMove(uci: "d2d4", san: "d4",  averageRating: 1648, white: 1_687_400, draws: 437_200, black: 1_441_100),
            LichessMove(uci: "g1f3", san: "Nf3", averageRating: 1641, white: 312_800,  draws:  79_600, black:  266_500),
            LichessMove(uci: "c2c4", san: "c4",  averageRating: 1659, white: 248_600,  draws:  65_800, black:  211_900),
            LichessMove(uci: "g2g3", san: "g3",  averageRating: 1591, white:  68_400,  draws:  16_200, black:   58_300),
            LichessMove(uci: "b2b3", san: "b3",  averageRating: 1573, white:  43_200,  draws:   9_800, black:   36_900),
            LichessMove(uci: "f2f4", san: "f4",  averageRating: 1554, white:  28_700,  draws:   5_100, black:   24_500),
            LichessMove(uci: "c2c3", san: "c3",  averageRating: 1538, white:  12_100,  draws:   2_600, black:   10_400),
            LichessMove(uci: "b1c3", san: "Nc3", averageRating: 1544, white:  11_400,  draws:   2_300, black:    9_800),
            LichessMove(uci: "d2d3", san: "d3",  averageRating: 1521, white:   8_300,  draws:   1_700, black:    7_100),
        ],
        opening: Opening(eco: "A00", name: "Starting Position")
    )
}
