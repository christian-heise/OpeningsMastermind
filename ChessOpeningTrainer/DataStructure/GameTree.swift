//
//  GameTree.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.04.23.
//


import Foundation
import SwiftUI
import ChessKit

class GameTree: ObservableObject, Identifiable, Codable, Hashable {
    static func == (lhs: GameTree, rhs: GameTree) -> Bool {
        return lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    let name: String

    let rootNode: GameNode
    let userColor: PieceColor
    
    let pgnString: String
    
    var gameCopy: Game? = nil
    
    let date: Date
    
    var lastPlayed: Date
    
    @Published var currentNode: GameNode?
    @Published var gameState: Int = 0
    @Published var rightMove: Move? = nil
    
    var progress: Double {
//        return Double.random(in: 0...1)
        return self.userColor == .white ? 1-self.rootNode.progress : 1-self.rootNode.children.first!.progress
    }
    
    init(with gametree: GameTree) {
        self.name = gametree.name
        self.rootNode = gametree.rootNode
        self.currentNode = gametree.rootNode
        self.userColor = gametree.userColor
        self.pgnString = gametree.pgnString
        
        self.date = Date()
        self.lastPlayed = Date()
    }
    
    init(name: String, rootNode: GameNode, userColor: PieceColor, pgnString: String = "") {
        self.name = name
        self.rootNode = rootNode
        self.currentNode = rootNode
        self.userColor = userColor
        self.pgnString = pgnString
        
        self.date = Date()
        self.lastPlayed = Date()
    }
    
    init(name: String, pgnString: String, userColor: PieceColor) {
        self.name = name
        self.userColor = userColor
        
        let rootNode = GameTree.decodePGN(pgnString: pgnString)
        
        self.rootNode = rootNode
        self.currentNode = rootNode
        self.pgnString = pgnString
        
        self.date = Date()
        self.lastPlayed = Date()
    }
    
    static func example() -> GameTree {
        return ExamplePGN.list.randomElement()!.gameTree!
    }
    
    public func generateMove(game: Game) -> (Move?, GameNode?) {
        guard let currentNode = self.currentNode else { return (nil, nil)}
        
        if currentNode.children.count == 1 {
            let newNode = currentNode.children.first!
            let decoder = SanSerialization.default
            let generatedMove = decoder.move(for: newNode.move, in: game)
            return (generatedMove, newNode)
        }
        
        // Probabilities based on Mistakes
        let probabilitiesMistakes = currentNode.children.map({$0.mistakesRate / currentNode.children.map({$0.mistakesRate}).reduce(0, +)})
        
        
        // Probability based on Depth
        let depthArray: [Double] = currentNode.children.map({Double($0.depth) * Double($0.depth)})
        let summedDepth = depthArray.reduce(0, +)
        
        var probabilitiesDepth = [Double]()
        
        if summedDepth == 0 {
            probabilitiesDepth = Array(repeating: 1 / Double(currentNode.children.count), count: currentNode.children.count)
        } else {
            probabilitiesDepth = depthArray.map({$0 / Double(summedDepth)})
        }
        
        // Combine probabilities
        var probabilities = zip(probabilitiesMistakes,probabilitiesDepth).map() {$0 * Double(probabilitiesMistakes.count) * $1}
        probabilities = probabilities.map({$0 / probabilities.reduce(0,+)})
//        let probabilities = zip(probabilitiesMistakes,probabilitiesDepth).map() {($0 + $1)/2}
        print("Depth: \(probabilitiesDepth)")
        print("Mistake: \(probabilitiesMistakes)")
        print("Total: \(probabilities)")
        
        // Make random Int between 0 and 1000
        var randomInt = Int.random(in: 0...1000)
        
        for i in 0 ..< probabilities.count {
            if randomInt > Int(probabilities[i] * Double(1000)) {
                randomInt -= Int(probabilities[i]*1000)
                continue
            } else {
                let newNode = currentNode.children[i]
                let decoder = SanSerialization.default
                let generatedMove = decoder.move(for: newNode.move, in: game)
                
                return (generatedMove, newNode)
            }
        }
        let newNode = currentNode.children.first!
        let decoder = SanSerialization.default
        let generatedMove = decoder.move(for: newNode.move, in: game)
        
        return (generatedMove, newNode)
    }
    
    func reset() {
        self.currentNode = self.rootNode
        self.gameState = 0
        self.rightMove = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decode(String.self, forKey: .name)
        self.pgnString = try container.decode(String.self, forKey: .pgnString)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        self.lastPlayed = try container.decodeIfPresent(Date.self, forKey: .lastPlayed) ?? Date()
        
        let rootNode =  try GameNode.decodeRecursively(from: decoder)
        self.rootNode = rootNode
        let userColorString = try container.decode(String.self, forKey: .userColor)
        self.userColor = userColorString=="white" ? .white : .black
        
        self.currentNode = rootNode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let userColorString = userColor == .white ? "white" : "black"
        
        try container.encode(name, forKey: .name)
        try container.encode(pgnString, forKey: .pgnString)
        try rootNode.encodeRecursively(to: encoder)
        try container.encode(userColorString, forKey: .userColor)
        
        try container.encode(date, forKey: .date)
        try container.encode(lastPlayed, forKey: .lastPlayed)
    }
    
    enum CodingKeys: String, CodingKey {
            case name, rootNode, userColor, pgnString, date, lastPlayed
        }
}
