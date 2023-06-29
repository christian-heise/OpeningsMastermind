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
    
    let fen: String
    
    var mistakesLast5Moves: [Date: Bool] = [:]
    let mistakeFactor = 0.85
    private var _depth: Int? // memorization cache
    
    var nextMoveColor: PieceColor {
        return self.parents.first?.moveColor.negotiated ?? .white
    }
    
    var lastTryWasMistake: Bool {
        guard let lastTryDate = mistakesLast5Moves.keys.max() else { return true }
        
        return mistakesLast5Moves[lastTryDate] ?? true
    }
    
    var streak: Int {
        var count = 0
        for key in mistakesLast5Moves.keys.sorted(by: >) {
            if mistakesLast5Moves[key] == false {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    var dueDate: Date {
        guard let lastTryDate = mistakesLast5Moves.keys.max() else { return Date(timeIntervalSince1970: 0) }
        
        if lastTryWasMistake {
            return lastTryDate
        } else {
            switch self.streak {
            case 1:
                return Date(timeInterval: 1*24*60*60, since: lastTryDate)
            case 2:
                return Date(timeInterval: 7*24*60*60, since: lastTryDate)
            case 3:
                return Date(timeInterval: 16*24*60*60, since: lastTryDate)
            case 4:
                return Date(timeInterval: 35*24*60*60, since: lastTryDate)
            default:
                return Date(timeInterval: 70*24*60*60, since: lastTryDate)
            }
        }
    }
    
    init(children: [MoveNode] = [], parents: [MoveNode] = [], fen: String, comment: String? = nil) {
        self.children = children
        self.parents = parents
        self.fen = fen
        self.comment = comment
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        children = try container.decode([MoveNode].self, forKey: .children)
        parents = []
        comment = try container.decode(String?.self, forKey: .comment)

        if let mistakesLast5Moves = try container.decodeIfPresent([Date:Bool].self, forKey: .mistakesLast5Moves) {
            self.mistakesLast5Moves = mistakesLast5Moves
        } else {
            var dict = [Date:Bool]()
            let array = try container.decode([Int].self, forKey: .mistakesLast5Moves)
            var flag = false
            for i in 0..<array.count {
                let randomDate = Double(Int.random(in: 0..<100000) + i*100000)
                if array[i] == 0 {
                    dict[Date(timeIntervalSince1970: randomDate)] = false
                    flag = true
                } else if array[i] == 1 && flag {
                    dict[Date(timeIntervalSince1970: randomDate)] = true
                }
            }
        }

        fen = try container.decode(String.self, forKey: .fen)

        for child in children {
            child.parent = self
        }
    }
    required init(from decoder: Decoder, gameNodeDictionary: GameNodeDictionary) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        children = try container.decodeArray(MoveNode.self, forKey: .children, gameNodeDictionary: gameNodeDictionary)
        parents = []
        comment = try container.decode(String?.self, forKey: .comment)
        
        if let mistakesLast5Moves = try container.decodeIfPresent([Date:Bool].self, forKey: .mistakesLast5Moves) {
            self.mistakesLast5Moves = mistakesLast5Moves
        } else {
            var dict = [Date:Bool]()
            let array = try container.decode([Int].self, forKey: .mistakesLast5Moves)
            var flag = false
            for i in 0..<array.count {
                let randomDate = Double(Int.random(in: 0..<100000) + i*100000)
                if array[i] == 0 {
                    dict[Date(timeIntervalSince1970: randomDate)] = false
                    flag = true
                } else if array[i] == 1 && flag {
                    dict[Date(timeIntervalSince1970: randomDate)] = true
                }
            }
        }
        
        fen = try container.decode(String.self, forKey: .fen)
        
        for child in children {
            child.parent = self
        }
    }
}

extension GameNode {
    var mistakesSum: Int {
        var sum: Int = 5
        for element in self.mistakesLast5Moves.values {
            if !element {
                sum -= 1
            }
        }
        return sum
    }
    
    var mistakesRate: Double {
        if children.isEmpty {
            return Double(mistakesSum)/5.0
        } else {
            return (children.map({$0.child.mistakesRate}).reduce(0, +)/Double(children.count) + Double(mistakesSum)/5.0) / 2.0
        }
    }
    
    var nodesBelow: Int {
        if self.children.isEmpty {
            return 0
        } else {
            return children.map({$0.child.nodesBelow + 1}).reduce(0,+)
        }
    }
    
    var mistakesBelow: Int {
        if self.children.isEmpty {
            return 0
        } else {
            return children.map({$0.child.mistakesBelow + ($0.child.lastTryWasMistake ? 1 : 0)}).reduce(0,+)
        }
    }
    
    var progress: Double {
        return Double(mistakesBelow) / Double(nodesBelow)
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
        try container.encode(fen, forKey: .fen)
    }
    enum CodingKeys: String, CodingKey {
        case children, comment, mistakesLast5Moves, fen
    }
}

extension CodingUserInfoKey {
    static let gameNodeDictionary = CodingUserInfoKey(rawValue: "gameNodeDictionary")!
}
class GameNodeDictionary {
    var nodes: [String: GameNode] = [:]

    func addNode(_ node: GameNode) {
        nodes[node.fen] = node
    }

    func getNode(_ fen: String) -> GameNode? {
        return nodes[fen]
    }
}

//class GameNodeDecoder: Decoder {
//    let userInfo: [CodingUserInfoKey: Any] = [:]
//    let codingPath: [CodingKey] = []
//    private let innerDecoder: Decoder
//    private let gameNodeDictionary: GameNodeDictionary
//
//    init(decoder: Decoder, gameNodeDictionary: GameNodeDictionary) {
//        self.innerDecoder = decoder
//        self.gameNodeDictionary = gameNodeDictionary
//    }
//
//    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
//        return try innerDecoder.container(keyedBy: type)
//    }
//
//    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
//        return try innerDecoder.unkeyedContainer()
//    }
//
//    func singleValueContainer() throws -> SingleValueDecodingContainer {
//        return try innerDecoder.singleValueContainer()
//    }
//
//    func decodeGameNode() throws -> GameNode {
//        return try GameNode(from: innerDecoder, gameNodeDictionary: gameNodeDictionary)
//    }
//}

extension KeyedDecodingContainer {
    func decode(_ type: GameNode.Type, forKey key: KeyedDecodingContainer<K>.Key, gameNodeDictionary: GameNodeDictionary) throws -> GameNode {
        let decoder = try superDecoder(forKey: key)
        return try GameNode(from: decoder, gameNodeDictionary: gameNodeDictionary)
    }
    func decode(_ type: MoveNode.Type, forKey key: KeyedDecodingContainer<K>.Key, gameNodeDictionary: GameNodeDictionary) throws -> MoveNode {
        let decoder = try superDecoder(forKey: key)
        return try MoveNode(from: decoder, gameNodeDictionary: gameNodeDictionary)
    }
    
    func decodeArray(_ type: MoveNode.Type, forKey key: KeyedDecodingContainer<K>.Key, gameNodeDictionary: GameNodeDictionary) throws -> [MoveNode] {
        var container = try nestedUnkeyedContainer(forKey: key)
        var moveNodes: [MoveNode] = []

        while !container.isAtEnd {
            let moveNode = try container.decode(MoveNode.self, gameNodeDictionary: gameNodeDictionary)
            moveNodes.append(moveNode)
        }

        return moveNodes
    }
}
extension UnkeyedDecodingContainer {
    mutating func decode(_ type: MoveNode.Type, gameNodeDictionary: GameNodeDictionary) throws -> MoveNode {
        let decoder = try superDecoder()
        return try MoveNode(from: decoder, gameNodeDictionary: gameNodeDictionary)
    }
}

