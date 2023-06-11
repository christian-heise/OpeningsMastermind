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
    
    var mistakesLast5Moves: [Int] = Array(repeating: 1, count: 5)
    let mistakeFactor = 0.85
    private var _depth: Int? // memorization cache
    
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
        mistakesLast5Moves = try container.decode([Int].self, forKey: .mistakesLast5Moves)
        
        for child in children {
            child.parent = self
        }
    }
    enum NodeError: Error {
        case moveNotExists
    }
}

extension GameNode {
    var mistakes: Double {
        let exp = 1.4
        return pow(Double(mistakesLast5Moves.reduce(0, +)),exp) / pow(5.0,exp-1)
    }
    
    var mistakesRate: Double {
        if children.isEmpty {
            return mistakes/5
        } else {
            return (children.map({$0.child.mistakesRate}).reduce(0, +)/Double(children.count) + mistakes/5.0) / 2.0
        }
    }
    var nodesBelow: Double {
        if self.children.isEmpty {
            return 0
        } else {
            return children.map({Double($0.child.nodesBelow) * mistakeFactor + 1}).reduce(0,+)
        }
    }
    
    var mistakesBelow: Double {
        if self.children.isEmpty {
            return 0
        } else {
            return children.map({Double($0.child.mistakesBelow) * mistakeFactor + Double($0.child.mistakesLast5Moves.suffix(2).reduce(0,+))}).reduce(0,+)
        }
    }
    
    var progress: Double {
        return Double(mistakesBelow) / Double(nodesBelow) / 2.0
    }
    
    var depth: Int {
        if let cachedDepth = _depth {
            return cachedDepth
        }
        
        if children.isEmpty {
            _depth = 0
        } else if children.count == 1 {
            _depth = children.first!.child.depth + 1
        } else {
            _depth = children.map { $0.child.depth }.max()! + 1
        }
        
        return _depth!
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
        try container.encode(mistakesLast5Moves, forKey: .mistakesLast5Moves)
    }
    enum CodingKeys: String, CodingKey {
        case children, comment, mistakesLast5Moves
    }
    
//    static func decode_0_7(from decoder: Decoder) throws -> GameNode {
//        let container = try decoder.container(keyedBy: CodingKeys_0_7.self)
//        
//        let mistakesLast5Moves = try container.decodeIfPresent([Int].self, forKey: .mistakesLast5Moves)
//        
//        let move = try container.decode(String.self, forKey: .move)
//        
//        let comment = try container.decodeIfPresent(String.self, forKey: .comment)
//        
//        
//        let children = try container.decode([GameNode].self, forKey: .children)
//        
//        let gameNode = GameNode
//        
//        let moveNode = MoveNode(moveString: move, move: nil, child: nil, parent: <#T##GameNode#>)
//        
//        let annotation = try container.decodeIfPresent(String.self, forKey: .annotation)
//    }
    enum CodingKeys_0_7: String, CodingKey {
        case move, children, moveNumber, moveColor, parent, mistakesLast5Moves, comment, annotation
    }
}
