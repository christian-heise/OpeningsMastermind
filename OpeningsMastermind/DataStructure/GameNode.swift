//
//  GameNode.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 09.06.23.
//

import Foundation
import ChessKit

class GameNode: Codable, Hashable {
    let id = UUID()
    var children: [MoveNode]
    var parents: [MoveNode]
    
    var comment: String?
    
    init(children: [MoveNode] = [], parents: [MoveNode] = [], comment: String? = nil) {
        self.children = children
        self.parents = parents
        self.comment = comment
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        children = try container.decode([MoveNode].self, forKey: .children)
        parents = []
        comment = try container.decode(String?.self, forKey: .comment)
        
        for child in children {
            child.parent = self
        }
    }
    enum NodeError: Error {
        case moveNotExists
    }
}

extension GameNode {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: GameNode, rhs: GameNode) -> Bool {
        lhs.id == rhs.id
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(children, forKey: .children)
        try container.encode(comment, forKey: .comment)
    }
    enum CodingKeys: String, CodingKey {
        case children, comment
    }
}
