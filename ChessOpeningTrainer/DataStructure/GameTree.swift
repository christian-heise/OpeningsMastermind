//
//  GameTree.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.04.23.
//


import Foundation
import SwiftUI
import ChessKit

class GameTree: ObservableObject, Identifiable, Codable {
    let name: String
    let id = UUID()
    let rootNode: GameNode
    let userColor: PieceColor
    
    let pgnString: String
    
    var gameCopy: Game? = nil
    
    @Published var currentNode: GameNode?
    @Published var gameState: Int = 0
    @Published var rightMove: Move? = nil
    
    init(name: String, rootNode: GameNode, userColor: PieceColor, pgnString: String = "") {
        self.name = name
        self.rootNode = rootNode
        self.currentNode = rootNode
        self.userColor = userColor
        self.pgnString = pgnString
    }
    
    init(name: String, pgnString: String, userColor: PieceColor) {
        self.name = name
        self.userColor = userColor
        self.rootNode = GameTree.decodePGN(pgnString: pgnString)
        self.currentNode = self.rootNode
        self.pgnString = pgnString
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
        
        // Probabilities based on Misstakes
        
        let probabilitiesMistakes = currentNode.children.map({$0.mistakesRate / currentNode.children.map({$0.mistakesRate}).reduce(0, +)})
        
//        if weightedMistakesSum == 0 {
//            probabilitiesMistakes = Array(repeating: 1 / Double(currentNode.children.count), count: currentNode.children.count)
//        } else {
//            probabilitiesMistakes = weightedMistakes.map({$0 / Double(weightedMistakesSum)})
//        }
        
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
//        let probabilities = probabilitiesDepth
        let probabilities = zip(probabilitiesMistakes,probabilitiesDepth).map() {($0 + $1)/2}
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

        name = try container.decode(String.self, forKey: .name)
        pgnString = try container.decode(String.self, forKey: .pgnString)
        
        rootNode =  try GameNode.decodeRecursively(from: decoder)
        
//        rootNode = try container.decode(GameNode.self, forKey: .rootNode)
        
        let userColorString = try container.decode(String.self, forKey: .userColor)
        userColor = userColorString=="white" ? .white : .black
        
        currentNode = rootNode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let userColorString = userColor == .white ? "white" : "black"
        
        try container.encode(name, forKey: .name)
        try container.encode(pgnString, forKey: .pgnString)
        try rootNode.encodeRecursively(to: encoder)
        try container.encode(userColorString, forKey: .userColor)
    }
    
    enum CodingKeys: String, CodingKey {
            case name, rootNode, userColor, pgnString
        }
}
