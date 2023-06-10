//
//  MoveNode.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 10.06.23.
//

import Foundation
import ChessKit

class MoveNode: Codable {
    let moveString: String
    let move: Move
    
    let annotation: String?
    
    var child: GameNode
    var parent: GameNode?
    
    init(moveString: String, move: Move, annotation: String? = nil, child: GameNode, parent: GameNode) {
        self.moveString = moveString
        self.move = move
        self.annotation = annotation
        self.child = child
        self.parent = parent
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        child = try container.decode(GameNode.self, forKey: .child)
        moveString = try container.decode(String.self, forKey: .moveString)
        annotation = try container.decode(String?.self, forKey: .annotation)
        move = Move(string: try container.decode(String.self, forKey: .move))
        
        child.parents += [self]
    }
}

extension MoveNode {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(child, forKey: .child)
        try container.encode(annotation, forKey: .annotation)
        try container.encode(moveString, forKey: .moveString)
        try container.encode(move.description, forKey: .move)
    }
    
    enum CodingKeys: String, CodingKey {
        case child, moveString, move, annotation
    }
}
