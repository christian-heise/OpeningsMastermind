//
//  decodePGN.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import Foundation

extension GameTree {
    static func decodePGN(pgnString: String) -> GameNode? {
        
        let chapters = pgnString.split(separator: "\n\n").filter({$0.hasPrefix("1.")})
        
        let rootNode = GameNode(moveString: "")
        
        let regex = try! NSRegularExpression(pattern: "\\{.*?\\}", options: [NSRegularExpression.Options.dotMatchesLineSeparators])
        
        var currentNode = rootNode
        var newNode = rootNode
        
        var variationNodes: [GameNode] = []
        
//        var modifiedMove = ""
        
        for i in 0..<chapters.count {
            let pgnWithoutComments = regex.stringByReplacingMatches(in: String(chapters[i]), options: [], range: NSRange(location: 0, length: chapters[i].utf16.count), withTemplate: "")
            
            let rawMoves = pgnWithoutComments.components(separatedBy: " ").filter({$0 != ""})
            
            print(pgnWithoutComments)
            
            currentNode = rootNode
//            newNode = rootNode

            for rawMove in rawMoves {
                
                if isMoveNumberWhite(rawMove) {
                    continue
                } else if isMoveNumberBlack(rawMove) {
                    continue
                }
                if isVariationMoveNumber(rawMove) {
                    variationNodes.append(currentNode)
                    currentNode = currentNode.parent!
                    continue
                }
                if rawMove.hasSuffix(")") {
                    var modifiedMove = rawMove
                    while modifiedMove.hasSuffix(")") {
                        modifiedMove = String(modifiedMove.dropLast())
                        if !modifiedMove.isEmpty && !modifiedMove.hasPrefix("$") && !modifiedMove.hasSuffix(")") {
                            currentNode = addMoveToTree(modifiedMove)
                        }
                        currentNode = variationNodes.last!
                        variationNodes.removeLast()
                    }
                } else if rawMove == "*" {
                    continue
                } else if rawMove == "1-0" || rawMove == "0-1"{
                continue
                } else if rawMove.hasPrefix("$") {
                 continue
                } else {
                    currentNode = addMoveToTree(rawMove)
                }
            }
        }
        
        return rootNode
        
        func addMoveToTree(_ rawMove: String) -> GameNode {
            let move = clean(rawMove)
            if move == ")" {
                print("whaaat")
            }
            if !currentNode.children.contains(where: {$0.move==move}) {
                newNode = GameNode(moveString: move, parent: currentNode)
                currentNode.children.append(newNode)
            } else {
                newNode = currentNode.children.first(where: {$0.move==move})!
            }
            return newNode
        }
        
        func clean(_ rawMove: String) -> String {
            if rawMove.hasSuffix("!?") || rawMove.hasSuffix("?!") || rawMove.hasSuffix("!!") || rawMove.hasSuffix("??") {
                return String(rawMove.dropLast(2))
            } else if rawMove.hasSuffix("!") || rawMove.hasSuffix("?") {
                return String(rawMove.dropLast())
            } else {
                return rawMove
            }
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
    }
}
