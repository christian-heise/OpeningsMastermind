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
    
    var moveColor: PieceColor {
        if let lastMove = parent?.parents.first {
            return lastMove.moveColor.negotiated
        } else {
            return .white
        }
    }
    
    var halfMoveNumber: Int {
        if let lastMove = parent?.parents.first {
            return lastMove.halfMoveNumber + 1
        } else {
            return 1
        }
    }
    
    init(moveString: String, move: Move, annotation: String? = nil, child: GameNode, parent: GameNode) {
        self.moveString = moveString
        self.move = move
        self.annotation = annotation
        self.child = child
        self.parent = parent
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let child = try container.decode(GameNode.self, forKey: .child)
        
        if let gameNodeDictionary = decoder.userInfo[.gameNodeDictionary] as? GameNodeDictionary, let existingGameNode = gameNodeDictionary.getNode(child.fen) {
            self.child = existingGameNode
        } else {
            self.child = child
            
            // Add the new GameNode to the dictionary
            if let gameNodeDictionary = decoder.userInfo[.gameNodeDictionary] as? GameNodeDictionary {
                gameNodeDictionary.addNode(child)
            }
        }
        
        moveString = try container.decode(String.self, forKey: .moveString)
        annotation = try container.decode(String?.self, forKey: .annotation)
        move = Move(string: try container.decode(String.self, forKey: .move))
        
        self.child.parents += [self]
    }
    
    required init(from decoder: Decoder, gameNodeDictionary: GameNodeDictionary) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let child = try container.decode(GameNode.self, forKey: .child, gameNodeDictionary: gameNodeDictionary)
        
        if let existingGameNode = gameNodeDictionary.getNode(child.fen) {
            self.child = existingGameNode
        } else {
            self.child = child
            gameNodeDictionary.addNode(child)
        }
        
        moveString = try container.decode(String.self, forKey: .moveString)
        annotation = try container.decode(String?.self, forKey: .annotation)
        move = Move(string: try container.decode(String.self, forKey: .move))
        
        self.child.parents += [self]
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
