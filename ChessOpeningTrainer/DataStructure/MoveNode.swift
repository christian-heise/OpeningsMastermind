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
    
    var comment: String?
    let annotation: String?
    
    var mistakesLast5Moves: [Int] = Array(repeating: 1, count: 5)
    
    var mistakesLastMoveCount: Double {
        let exp = 1.4
        return pow(Double(mistakesLast5Moves.reduce(0, +)),exp) / pow(5.0,exp-1)
    }
    
    var mistakesRate: Double {
        var array: [Double] = []
        if children.isEmpty {
            return mistakesLastMoveCount/5
        } else {
            for child in children {
                if !child.children.isEmpty {
                    array.append(child.children.map({$0.mistakesRate}).reduce(0, +)/Double(child.children.count))
                }
            }
            if array.isEmpty {
                return Double(mistakesLast5Moves.reduce(0, +))/5
            } else {
                return (array.reduce(0, +)/Double(array.count)*1 + mistakesLastMoveCount/5) / 2.0
            }
        }
    }
    
    let mistakeFactor = 0.85
    var nodesBelow: Double {
        var array: [Double] = []
        if self.children.isEmpty {
            return 0
        } else {
            for child in self.children {
                if !child.children.isEmpty {
                    array.append(child.children.map({Double($0.nodesBelow) * mistakeFactor + 1}).reduce(0,+))
                }
            }
            if array.isEmpty {
                return 0
            } else {
                return array.reduce(0,+)
            }
        }
    }
    var mistakesBelow: Double {
        var array: [Double] = []
        if self.children.isEmpty {
            return 0
        } else {
            for child in self.children {
                if !child.children.isEmpty {
                    array.append(child.children.map({Double($0.mistakesBelow) * mistakeFactor + Double($0.mistakesLast5Moves.suffix(2).reduce(0,+))}).reduce(0,+))
                }
            }
            if array.isEmpty {
                return 0
            } else {
                return array.reduce(0,+)
            }
        }
    }
    
    var progress: Double {
        return Double(mistakesBelow) / Double(nodesBelow) / 2
    }
    
    private var _depth: Int? // memorization cache
    
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
    
    init(moveString: String, comment: String? = nil, annotation: String? = nil, parent: GameNode? = nil) {
        self.move = moveString
        
        self.comment = comment
        self.annotation = annotation
        
        if let parent = parent {
            self.moveNumber = parent.moveColor == .white ? parent.moveNumber : parent.moveNumber + 1
            self.moveColor = parent.moveColor == .white ? .black : .white
            self.parent = parent
        }
    }
    
    static func ==(lhs: GameNode, rhs: GameNode) -> Bool {
        return lhs.move == rhs.move && lhs.moveNumber == rhs.moveNumber && lhs.moveColor == rhs.moveColor && lhs.parent == rhs.parent
    }
    
    public func databaseContains(move: Move, in game: Game) -> (found: Bool, newNode: GameNode) {
        let decoder = SanSerialization.default
        let san = decoder.correctSan(for: move, in: game)
        
        let isInData = self.children.contains(where: {$0.move == san})
        if isInData {
            return (true, self.children.first(where: {$0.move == san})!)
        } else {
            return (false, self)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        mistakesLast5Moves = try container.decodeIfPresent([Int].self, forKey: .mistakesLast5Moves) ?? Array(repeating: 1, count: 5)
        children = try container.decode([GameNode].self, forKey: .children)
        move = try container.decode(String.self, forKey: .move)
        moveNumber = try container.decode(Int.self, forKey: .moveNumber)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        annotation = try container.decodeIfPresent(String.self, forKey: .annotation)
        
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
        
        try container.encode(mistakesLast5Moves, forKey: .mistakesLast5Moves)
        try container.encode(children, forKey: .children)
        try container.encode(moveNumber, forKey: .moveNumber)
        try container.encode(moveColorString, forKey: .moveColor)
        try container.encode(move, forKey: .move)
        try container.encode(comment, forKey: .comment)
        try container.encode(annotation, forKey: .annotation)
    }
    
    func encodeRecursively(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let moveColorString = moveColor == .white ? "white" : "black"
        
        try container.encode(children, forKey: .children)
        try container.encode(mistakesLast5Moves, forKey: .mistakesLast5Moves)
        try container.encode(moveNumber, forKey: .moveNumber)
        try container.encode(moveColorString, forKey: .moveColor)
        try container.encode(move, forKey: .move)
        try container.encode(comment, forKey: .comment)
        try container.encode(annotation, forKey: .annotation)
    }
    
    static func decodeRecursively(from decoder: Decoder) throws -> GameNode {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mistakesLast5Moves = try container.decodeIfPresent([Int].self, forKey: .mistakesLast5Moves)
        
        let move = try container.decode(String.self, forKey: .move)
        let moveNumber = try container.decode(Int.self, forKey: .moveNumber)
        let moveColorString = try container.decode(String.self, forKey: .moveColor)
        
        let comment = try container.decodeIfPresent(String.self, forKey: .comment)
        let annotation = try container.decodeIfPresent(String.self, forKey: .annotation)
        
        let children = try container.decode([GameNode].self, forKey: .children)
        
        let node = GameNode(moveString: move, comment: comment, annotation: annotation)
        
        node.mistakesLast5Moves = mistakesLast5Moves ?? Array(repeating: 1, count: 5)
        node.children = children
        node.moveNumber = moveNumber
        node.moveColor = moveColorString == "white" ? .white : .black
        
        for i in 0..<children.count {
            node.children[i].parent = node
        }
        return node
    }
    
    enum CodingKeys: String, CodingKey {
            case move, children, moveNumber, moveColor, parent, mistakesLast5Moves, comment, annotation
        }
}
