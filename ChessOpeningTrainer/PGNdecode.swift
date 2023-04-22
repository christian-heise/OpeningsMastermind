//
//  PGNdecode.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 21.04.23.
//

import Foundation
import ChessKit

func decodePGN(pgnString: String) throws -> GameNode {
    
    let movesComponentPGN = pgnString.split(separator: "\n").filter({$0.hasPrefix("1.")}).first!
    
    let regex = try! NSRegularExpression(pattern: "\\{.*?\\}", options: [])
    let range = NSMakeRange(0, movesComponentPGN.utf16.count)
    let modifiedString = regex.stringByReplacingMatches(in: String(movesComponentPGN), options: [], range: range, withTemplate: "")
    print(modifiedString)
    
    let moves = modifiedString.components(separatedBy: " ").filter({$0 != ""})
    print(moves)
    
    let rootNode = GameNode(moveString: "")
    
    var currentNode = rootNode
    
    var variationStart: [Int] = []
    var variationMove: [String] = []
    
    var counter = 0
    
    var newNode = rootNode
    
    for move in moves {
        if isMoveNumberWhite(String(move)) {
            continue
        } else if isMoveNumberBlack(String(move)) {
            continue
        }
        if isVariationMoveNumber(String(move)) {
            variationStart.append(counter)
            variationMove.append(currentNode.move)
            currentNode = currentNode.parent!
            continue
        }
        
        
        
        if move.last == ")" {
            let modifiedMove = String(move.dropLast())
            newNode = GameNode(moveString: modifiedMove, parent: currentNode)
            currentNode.children.append(newNode)
            currentNode = newNode
            counter += 1
            guard let lastVariationStart = variationStart.last else {throw PGNDecodingError.variationStart}
            while counter > lastVariationStart {
                currentNode = currentNode.parent!
                counter -= 1
            }
            currentNode = currentNode.children.first(where: {$0.move == variationMove.last!})!
            variationMove.removeLast()
            variationStart.removeLast()
        } else if move == "*" {
            return rootNode
        } else {
            newNode = GameNode(moveString: String(move), parent: currentNode)
            currentNode.children.append(newNode)
            currentNode = newNode
            counter += 1
        }
    }
    
    return rootNode
}

func isMoveNumberWhite(_ str: String) -> Bool {
    let pattern = #"^\d+\.$"#
    return str.range(of: pattern, options: .regularExpression) != nil
}
func isMoveNumberBlack(_ str: String) -> Bool {
    let pattern = #"^\d+\.\.\.$"#
    return str.range(of: pattern, options: .regularExpression) != nil
}

func isVariationMoveNumber(_ str: String) -> Bool {
    let pattern = #"^\(\d+\."#
    return str.range(of: pattern, options: .regularExpression) != nil
}
func isVariationEndMove(_ str: String) -> Bool {
    let pattern = #"^\a\d\)$"#
    return str.range(of: pattern, options: .regularExpression) != nil
}

enum PGNDecodingError: Error {
    case wrongFormatting
    case variationStart
}
