//
//  GameTreeNew.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 09.06.23.
//

import Foundation
import ChessKit

struct GameTree: Codable, Hashable {
    let id: UUID
    
    var name: String
    var userColor: PieceColor
    let rootNode: GameNode
    
    let pgnString: String
    let dateAdded: Date
    
    var dateLastPlayed: Date
    
    var progress: Double {
        1-rootNode.progress
    }
    
    init(name: String, pgnString: String, userColor: PieceColor) {
        let decoder = PGNDecoder.default
        
        self.id = UUID()
        self.name = name
        self.userColor = userColor
        self.rootNode = decoder.decodePGN(pgnString: pgnString)
        self.pgnString = pgnString
        self.dateAdded = Date()
        self.dateLastPlayed = Date(timeIntervalSince1970: 0)
    }
    
    init(fromOld oldTree: GameTreeOld) {
        let decoder = PGNDecoder.default
        
        self.id = oldTree.id
        self.name = oldTree.name
        self.userColor = oldTree.userColor
        
        self.dateAdded = oldTree.date
        self.dateLastPlayed = oldTree.lastPlayed
        
        if oldTree.pgnString != "" {
            self.pgnString = oldTree.pgnString
            self.rootNode = decoder.decodePGN(pgnString: oldTree.pgnString)
        } else {
            let oldRootNode = oldTree.rootNode
            let rootNode = GameTree.convert(oldNode: oldRootNode, game: Game(position: startingGamePosition))
            self.rootNode = rootNode
            self.pgnString = ""
        }
    }
    
    static func convert(oldNode: GameNodeOld, game: Game) -> GameNode {
        let node = GameNode()
        node.comment = oldNode.comment
        var moveChildren: [MoveNode] = []
        for child in oldNode.children {
            let move = SanSerialization.default.move(for: child.move, in: game)
            let newGame = game.deepCopy()
            newGame.make(move: move)
            
            let childGameNode = convert(oldNode: child, game: newGame)
            let moveChild = MoveNode(moveString: child.move, move: move, child: childGameNode, parent: node)
            childGameNode.parents = [moveChild]
            moveChildren.append(moveChild)
        }
        node.children = moveChildren
        return node
    }
    
    static func example() -> GameTree {
        let example = ExamplePGN.list.randomElement()!
        return GameTree(name: example.name, pgnString: example.pgnString ?? "", userColor: example.userColor)
    }
}

extension GameTree {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        
        self.name = try container.decode(String.self, forKey: .name)
        let userColorString = try container.decode(String.self, forKey: .userColor)
        self.userColor = userColorString=="white" ? .white : .black
        self.rootNode = try container.decode(GameNode.self, forKey: .rootNode)
        
        self.pgnString = try container.decode(String.self, forKey: .pgnString)
        self.dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        
        self.dateLastPlayed = try container.decodeIfPresent(Date.self, forKey: .dateLastPlayed) ?? Date(timeIntervalSince1970: 0)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(name, forKey: .name)
        let userColorString = userColor == .white ? "white" : "black"
        try container.encode(userColorString, forKey: .userColor)
        try container.encode(rootNode, forKey: .rootNode)
        
        try container.encode(pgnString, forKey: .pgnString)
        try container.encode(dateAdded, forKey: .dateAdded)
        
        try container.encode(dateLastPlayed, forKey: .dateLastPlayed)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, rootNode, userColor, pgnString, dateAdded, dateLastPlayed, id
    }
}
