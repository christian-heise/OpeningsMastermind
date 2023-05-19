//
//  LichessUserData.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.05.23.
//

import Foundation

struct LichessUserData: Codable {
    let perfs: LichessPerformance
    
    struct LichessPerformance: Codable {
        let blitz: LichessPerformanceTimeControl
        let bullet: LichessPerformanceTimeControl
        let rapid: LichessPerformanceTimeControl
        let classical: LichessPerformanceTimeControl
        
        struct LichessPerformanceTimeControl: Codable {
            let games: Int
            let rating: Int
            let rd: Int
            let prog: Int
            let prov: Bool
        }
    }
}
