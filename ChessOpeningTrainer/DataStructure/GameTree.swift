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
    let rootNode: GameNode?
    let userColor: PieceColor
    
    @Published var currentNode: GameNode?
    @Published var gameState: Int = 0
    @Published var rightMove: Move? = nil
    
    init(name: String, rootNode: GameNode, userColor: PieceColor) {
        self.name = name
        self.rootNode = rootNode
        self.currentNode = rootNode
        self.userColor = userColor
    }
    
    init(name: String, pgnString: String, userColor: PieceColor) {
        self.name = name
        self.userColor = userColor
        self.rootNode = GameTree.decodePGN(pgnString: pgnString)
        self.currentNode = self.rootNode
    }
    
    static func example() -> GameTree {
        return GameTree(name: "Example", pgnString: examplePGN, userColor: .white)
    }
    
    public func generateMove(game: Game) -> (Move?, GameNode?) {
        guard let currentNode = self.currentNode else { return (nil, nil)}
        
        let depthArray: [Double] = currentNode.children.map({Double($0.depth) * Double($0.depth)})
        let summedDepth = depthArray.reduce(0, +)
        
        let probabilities: [Double] = depthArray.map({Double($0) / Double(summedDepth)})
        
        var randomInt = Int.random(in: 0..<1000)
        
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
    
//    static private func decodePGN(pgnString: String) -> GameNode? {
//        
////        let movesComponentPGN = pgnString.split(separator: "\n").filter({$0.hasPrefix("1.")}).first!
//        
//        let chapters = pgnString.split(separator: "\n\n").filter({$0.hasPrefix("1.")})
//        
//        print(chapters.count)
//        
//        let rootNode = GameNode(moveString: "")
//        
//        let regex = try! NSRegularExpression(pattern: "\\{.*?\\}", options: [NSRegularExpression.Options.dotMatchesLineSeparators])
//        
//        var currentNode = rootNode
//        var variationStart: [Int] = []
//        var variationMove: [String] = []
//        var counter = 0
//        var newNode = rootNode
//        
//        var modifiedString = ""
//        var moves = [String]()
//        
//        var modifiedMove = ""
//        
//        var deepestMove = 1
//        
//        for i in 0..<chapters.count {
//            modifiedString = regex.stringByReplacingMatches(in: String(chapters[i]), options: [], range: NSRange(location: 0, length: chapters[i].utf16.count), withTemplate: "")
//            print(modifiedString)
//            
//            moves = modifiedString.components(separatedBy: " ").filter({$0 != ""})
//            
//            currentNode = rootNode
//            
//            variationStart = []
//            variationMove = []
//            
//            counter = 0
//            newNode = rootNode
//
//            for move in moves {
//                deepestMove = max(deepestMove, currentNode.moveNumber)
//                if isMoveNumberWhite(String(move)) {
//                    continue
//                } else if isMoveNumberBlack(String(move)) {
//                    continue
//                }
//                if isVariationMoveNumber(String(move)) {
//                    variationStart.append(counter)
//                    variationMove.append(currentNode.move)
//                    currentNode = currentNode.parent!
//                    continue
//                }
//                if move.last == ")" {
//                    modifiedMove = String(move.dropLast())
//                    if modifiedMove.isEmpty {
//                        newNode = currentNode
//                        counter -= 1
//                        guard let lastVariationStart = variationStart.last else {return nil}
//                        while counter > lastVariationStart {
//                            currentNode = currentNode.parent!
//                            counter -= 1
//                        }
////                        currentNode.depth = newNode.moveNumber
//                        currentNode = currentNode.parent!.children.first(where: {$0.move == variationMove.last!})!
//                        variationMove.removeLast()
//                        variationStart.removeLast()
//                    } else {
//                        if modifiedMove.hasSuffix("!?") || modifiedMove.hasSuffix("?!") || modifiedMove.hasSuffix("!!") || modifiedMove.hasSuffix("??") {
//                            modifiedMove = String(modifiedMove.dropLast(2))
//                        } else if modifiedMove.hasSuffix("!") || modifiedMove.hasSuffix("?") {
//                            modifiedMove = String(modifiedMove.dropLast())
//                        }
//                        if !currentNode.children.contains(where: {$0.move==modifiedMove}) {
//                            newNode = GameNode(moveString: modifiedMove, parent: currentNode)
//                            currentNode.children.append(newNode)
//                        } else {
//                            newNode = currentNode.children.first(where: {$0.move==modifiedMove})!
//                        }
//                        currentNode = newNode
////                        counter += 1
//                        guard let lastVariationStart = variationStart.last else {return nil}
//                        while counter > lastVariationStart {
//                            currentNode = currentNode.parent!
//                            counter -= 1
//                        }
////                        currentNode.depth = newNode.moveNumber
//                        currentNode = currentNode.parent!.children.first(where: {$0.move == variationMove.last!})!
//                        variationMove.removeLast()
//                        variationStart.removeLast()
//                    }
//                } else if move == "*" {
//                    continue
//                } else if move == "1-0" || move == "0-1"{
//                continue
//                } else if move.hasPrefix("$") {
//                 continue
//                } else {
//                    if modifiedMove.hasSuffix("!?") || modifiedMove.hasSuffix("?!") || modifiedMove.hasSuffix("!!") || modifiedMove.hasSuffix("??") {
//                        modifiedMove = String(modifiedMove.dropLast(2))
//                    } else if modifiedMove.hasSuffix("!") || modifiedMove.hasSuffix("?") {
//                        modifiedMove = String(modifiedMove.dropLast())
//                    } else {
//                        modifiedMove = move
//                    }
//                    if !currentNode.children.contains(where: {$0.move==modifiedMove}) {
//                        newNode = GameNode(moveString: modifiedMove, parent: currentNode)
//                        currentNode.children.append(newNode)
//                    } else {
//                        newNode = currentNode.children.first(where: {$0.move==modifiedMove})!
//                    }
//                    currentNode = newNode
//                    counter += 1
//                }
//            }
//        }
//        deepestMove = max(deepestMove, currentNode.moveNumber)
////        rootNode.depth = deepestMove
//        print(deepestMove)
//        return rootNode
//        
//        func isMoveNumberWhite(_ str: String) -> Bool {
//            let pattern = #"^\d+\.$"#
//            return str.range(of: pattern, options: .regularExpression) != nil
//        }
//        func isMoveNumberBlack(_ str: String) -> Bool {
//            let pattern = #"^\d+\.\.\.$"#
//            return str.range(of: pattern, options: .regularExpression) != nil
//        }
//
//        func isVariationMoveNumber(_ str: String) -> Bool {
//            let pattern = #"^\(\d+\."#
//            return str.range(of: pattern, options: .regularExpression) != nil
//        }
//        func isVariationEndMove(_ str: String) -> Bool {
//            let pattern = #"^\a\d\)$"#
//            return str.range(of: pattern, options: .regularExpression) != nil
//        }
//    }
//    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        
        rootNode =  try GameNode.decodeRecursively(from: decoder)
        
        let userColorString = try container.decode(String.self, forKey: .userColor)
        userColor = userColorString=="white" ? .white : .black
        
        currentNode = rootNode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let userColorString = userColor == .white ? "white" : "black"
        
        try container.encode(name, forKey: .name)
        try rootNode?.encodeRecursively(to: encoder)
        try container.encode(userColorString, forKey: .userColor)
    }
    
    enum CodingKeys: String, CodingKey {
            case name, rootNode, userColor
        }
}
