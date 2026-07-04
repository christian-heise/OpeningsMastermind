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

        if let mistakeArray =  try container.decodeIfPresent([Date:Bool].self, forKey: .mistakesLast5MovesDict) {
            self.mistakesLast5Moves = mistakeArray
        } else if let oldMistakeArray = try container.decodeIfPresent([Int].self, forKey: .mistakesLast5Moves) {
            var dict = [Date:Bool]()
            var flag = false
            for i in 0..<oldMistakeArray.count {
                let randomDate = Double(Int.random(in: 0..<100000) + i*100000)
                if oldMistakeArray[i] == 0 {
                    dict[Date(timeIntervalSince1970: randomDate)] = false
                    flag = true
                } else if oldMistakeArray[i] == 1 && flag {
                    dict[Date(timeIntervalSince1970: randomDate)] = true
                }
            }
            self.mistakesLast5Moves = dict
        } else {
            self.mistakesLast5Moves = [:]
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
        
        if let mistakeArray =  try container.decodeIfPresent([Date:Bool].self, forKey: .mistakesLast5MovesDict) {
            self.mistakesLast5Moves = mistakeArray
        } else if let oldMistakeArray = try container.decodeIfPresent([Int].self, forKey: .mistakesLast5Moves) {
            var dict = [Date:Bool]()
            var flag = false
            for i in 0..<oldMistakeArray.count {
                let randomDate = Double(Int.random(in: 0..<100000) + i*100000)
                if oldMistakeArray[i] == 0 {
                    dict[Date(timeIntervalSince1970: randomDate)] = false
                    flag = true
                } else if oldMistakeArray[i] == 1 && flag {
                    dict[Date(timeIntervalSince1970: randomDate)] = true
                }
            }
            self.mistakesLast5Moves = dict
        } else {
            self.mistakesLast5Moves = [:]
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

    /// Returns all nodes reachable from `self` (including `self`), ordered so that
    /// every child appears before its parent. Transpositions can create graphs with
    /// shared nodes and even cycles (e.g. a move sequence that returns to an earlier
    /// position); a back-edge to a node already on the current path is skipped, so
    /// that node's traversal "sees" it as not-yet-computed and treats it as zero.
    ///
    /// Not `private`: `GameTree` reuses this to sort large node lists by `nodesBelow`
    /// in a single pass instead of triggering a full subtree walk per comparison.
    func reachableNodesPostOrder() -> [GameNode] {
        var result: [GameNode] = []
        var visited: Set<ObjectIdentifier> = []
        var onStack: Set<ObjectIdentifier> = []
        var stack: [(node: GameNode, nextChildIndex: Int)] = [(self, 0)]
        onStack.insert(ObjectIdentifier(self))

        while !stack.isEmpty {
            let (node, childIndex) = stack[stack.count - 1]
            if childIndex < node.children.count {
                stack[stack.count - 1].nextChildIndex += 1
                let childNode = node.children[childIndex].child
                let childKey = ObjectIdentifier(childNode)
                if !visited.contains(childKey) && !onStack.contains(childKey) {
                    onStack.insert(childKey)
                    stack.append((childNode, 0))
                }
            } else {
                let key = ObjectIdentifier(node)
                if !visited.contains(key) {
                    visited.insert(key)
                    result.append(node)
                }
                onStack.remove(key)
                stack.removeLast()
            }
        }
        return result
    }

    var mistakesRate: Double {
        var memo: [ObjectIdentifier: Double] = [:]
        for node in reachableNodesPostOrder() {
            if node.children.isEmpty {
                memo[ObjectIdentifier(node)] = Double(node.mistakesSum) / 5.0
            } else {
                let childAverage = node.children
                    .map { memo[ObjectIdentifier($0.child)] ?? 0 }
                    .reduce(0, +) / Double(node.children.count)
                memo[ObjectIdentifier(node)] = (childAverage + Double(node.mistakesSum) / 5.0) / 2.0
            }
        }
        return memo[ObjectIdentifier(self)] ?? 0
    }

    /// Computes `nodesBelow` for every node reachable from `root` in a single pass.
    /// Use this instead of repeatedly reading `.nodesBelow` when sorting a list of
    /// nodes from the same tree - each access otherwise re-walks the whole subtree.
    static func nodesBelowMap(from root: GameNode) -> [ObjectIdentifier: Int] {
        var memo: [ObjectIdentifier: Int] = [:]
        for node in root.reachableNodesPostOrder() {
            var total = 0
            for moveNode in node.children {
                total += (memo[ObjectIdentifier(moveNode.child)] ?? 0) + 1
            }
            memo[ObjectIdentifier(node)] = total
        }
        return memo
    }

    var nodesBelow: Int {
        return GameNode.nodesBelowMap(from: self)[ObjectIdentifier(self)] ?? 0
    }

    var mistakesBelow: Int {
        var memo: [ObjectIdentifier: Int] = [:]
        for node in reachableNodesPostOrder() {
            var total = 0
            for moveNode in node.children {
                let child = moveNode.child
                total += (memo[ObjectIdentifier(child)] ?? 0) + (child.lastTryWasMistake ? 1 : 0)
            }
            memo[ObjectIdentifier(node)] = total
        }
        return memo[ObjectIdentifier(self)] ?? 0
    }

    var progress: Double {
        return Double(mistakesBelow) / Double(nodesBelow)
    }

    var depth: Int {
        if let cachedDepth = _depth {
            return cachedDepth
        }

        var memo: [ObjectIdentifier: Int] = [:]
        for node in reachableNodesPostOrder() {
            if let cachedDepth = node._depth {
                memo[ObjectIdentifier(node)] = cachedDepth
                continue
            }

            let depth: Int
            if node.children.isEmpty {
                depth = 0
            } else {
                depth = (node.children.map { memo[ObjectIdentifier($0.child)] ?? 0 }.max() ?? 0) + 1
            }
            node._depth = depth
            memo[ObjectIdentifier(node)] = depth
        }
        return memo[ObjectIdentifier(self)] ?? 0
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
        try container.encode(mistakesLast5Moves, forKey: .mistakesLast5MovesDict)
        try container.encode(fen, forKey: .fen)
    }
    enum CodingKeys: String, CodingKey {
        case children, comment, mistakesLast5Moves, fen, mistakesLast5MovesDict
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

