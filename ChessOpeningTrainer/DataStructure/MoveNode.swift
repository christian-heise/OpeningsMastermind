//
//  MoveNode.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.04.23.
//

import Foundation
import ChessKit


class GameNode: Codable, Equatable {
    let move: String
    
    var children: [GameNode] = []
    
    var moveNumber: Int = 0
    var moveColor: PieceColor = .black
    weak var parent: GameNode?
    
    var mistakeNextMove: Int
    
    var mistakesSum: Int {
        if children.isEmpty {
            return mistakeNextMove
        } else {
            return children.map({$0.mistakesSum}).reduce(0, +) + mistakeNextMove
        }
    }
    
    private var _depth: Int? // memoization cache
    
    var depth: Int {
        if let cachedDepth = _depth {
            return cachedDepth
        }
        
        if children.isEmpty {
            _depth = 0
        } else if children.count == 1 {
            _depth = children.first!.depth + 1
        } else {
            _depth = children.map { $0.depth }.max()! + 1
        }
        
        return _depth!
    }
    
    init(moveString: String, parent: GameNode? = nil) {
        self.move = moveString
        self.mistakeNextMove = 0
        
        if let parent = parent {
            self.moveNumber = parent.moveColor == .white ? parent.moveNumber : parent.moveNumber + 1
            self.moveColor = parent.moveColor == .white ? .black : .white
            self.parent = parent
        }
    }
    
    static func ==(lhs: GameNode, rhs: GameNode) -> Bool {
        return lhs.move == rhs.move && lhs.moveNumber == rhs.moveNumber && lhs.moveColor == rhs.moveColor && lhs.parent == rhs.parent
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        mistakeNextMove = try container.decode(Int.self, forKey: .mistakeNextMove)
        children = try container.decode([GameNode].self, forKey: .children)
        move = try container.decode(String.self, forKey: .move)
        moveNumber = try container.decode(Int.self, forKey: .moveNumber)
        let moveColorString = try container.decode(String.self, forKey: .moveColor)
        
        if moveColorString == "white" {
            moveColor = .white
        } else {
            moveColor = .black
        }
        for child in children {
            child.parent = self
        }
      }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let moveColorString = moveColor == .white ? "white" : "black"
        
        try container.encode(mistakeNextMove, forKey: .mistakeNextMove)
        try container.encode(children, forKey: .children)
        try container.encode(moveNumber, forKey: .moveNumber)
        try container.encode(moveColorString, forKey: .moveColor)
        try container.encode(move, forKey: .move)
//        try container.encode(depth, forKey: .depth)
    }
    
    func encodeRecursively(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let moveColorString = moveColor == .white ? "white" : "black"
        
        try container.encode(children, forKey: .children)
        try container.encode(mistakeNextMove, forKey: .mistakeNextMove)
        try container.encode(moveNumber, forKey: .moveNumber)
        try container.encode(moveColorString, forKey: .moveColor)
        try container.encode(move, forKey: .move)
//        try container.encode(depth, forKey: .depth)

//        for child in children {
//            try child.encodeRecursively(to: encoder)
//        }
    }
    
    static func decodeRecursively(from decoder: Decoder) throws -> GameNode {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mistakeNextMove = try container.decode(Int.self, forKey: .mistakeNextMove)
        let children = try container.decode([GameNode].self, forKey: .children)
        let move = try container.decode(String.self, forKey: .move)
        let moveNumber = try container.decode(Int.self, forKey: .moveNumber)
        let moveColorString = try container.decode(String.self, forKey: .moveColor)
//        let depth = try container.decode(Int?.self, forKey: .depth)
        
        let node = GameNode(moveString: move)
        node.mistakeNextMove = mistakeNextMove
        node.children = children
        node.moveNumber = moveNumber
        node.moveColor = moveColorString == "white" ? .white : .black
//        node.depth = depth
        
        for i in 0..<children.count {
            node.children[i].parent = node
        }
        return node
    }
    
    enum CodingKeys: String, CodingKey {
            case move, children, moveNumber, moveColor, parent, mistakeNextMove
        }
}
