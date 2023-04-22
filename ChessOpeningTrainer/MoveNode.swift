//
//  MoveNode.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.04.23.
//

import Foundation
import ChessKit


class GameNode {
    let move: String
    
    var children: [GameNode] = []
    
    var moveNumber: Int = 0
    var moveColor: PieceColor = .black
    var parent: GameNode?
    
    init(moveString: String, parent: GameNode? = nil) {
        self.move = moveString
        
        if let parent = parent {
            self.moveNumber = parent.moveColor == .white ? parent.moveNumber : parent.moveNumber + 1
            self.moveColor = parent.moveColor == .white ? .black : .white
            self.parent = parent
        }
    }
    
    public func databaseContains(move: Move, in game: Game) -> (Bool, GameNode) {
        let decoder = SanSerialization.default
        let san = decoder.san(for: move, in: game)
        
        let isInData = self.children.contains(where: {$0.move == san})
        if isInData {
            return (true, self.children.first(where: {$0.move == san})!)
        } else {
            return (false, self)
        }
    }
}
