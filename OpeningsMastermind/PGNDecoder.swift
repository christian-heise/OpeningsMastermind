//
//  PGNDecoder.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 12.06.23.
//

import Foundation
import ChessKit

class PGNDecoder {
    static let `default` = PGNDecoder()
    
    var progress: Double = 0.0
    
    func decodePGN(pgnString: String) -> [GameNode] {
        let rootNode = GameNode(fen: startingFEN)
        
        var game = Game(position: startingGamePosition)
        var currentNode = rootNode
        
        var allNodes: [GameNode] = [rootNode]
        var variationNodes: [GameNode] = []
        
        var dictPosition: [GameNode: Position] = [rootNode:startingGamePosition]
        var dictNode: [Position: GameNode] = [startingGamePosition:rootNode]
        var dictBoardNode: [Board: GameNode] = [startingGamePosition.board:rootNode]
        
        var currentString = ""
        var currentToken: Token = .unknown
        var specialCharacter = false
        var stringActive = false
        var nagActive = false
        
        var tagPairs: [String:String] = [:]
        
        var tagKey = ""
        
        for char in pgnString {
            switch currentToken {
            case .comment:
                switch char {
                case "}":
                    if currentNode.comment == nil {
                        currentNode.comment = currentString
                    } else {
                        currentNode.comment!.append("\n" + currentString)
                    }
                    currentString = ""
                    currentToken = .unknown
                default:
                    currentString.append(char)
                }
            case .tagPair:
                if stringActive {
                    switch char {
                    case "\\":
                        if specialCharacter {
                            currentString.append(char)
                            specialCharacter = false
                        } else {
                            specialCharacter = true
                        }
                    case "\"":
                        if stringActive && !specialCharacter {
                            stringActive = false
                        } else if !stringActive {
                            stringActive = true
                            currentString = ""
                            specialCharacter = false
                        } else {
                            currentString.append(char)
                            specialCharacter = false
                        }
                    default:
                        currentString.append(char)
                    }
                } else {
                    switch char {
                    case "]":
                        tagPairs[tagKey] = currentString
                        currentToken = .unknown
                        currentString = ""
                        break
                    case " ":
                        tagKey = currentString
                        currentString = ""
                    case "\"":
                        stringActive = true
                        currentString = ""
                    default:
                        currentString.append(char)
                    }
                }
            case .unknown:
                switch char {
                case "[":
                    currentString = ""
                    currentToken = .tagPair
                case "{":
                    currentString = ""
                    currentToken = .comment
                case "(":
                    currentNode = addMoveToTree(currentString)
                    currentString = ""
                    
                    variationNodes.append(currentNode)
                    currentNode = currentNode.parents.last!.parent!
                    game = Game(position: dictPosition[currentNode]!)
                case ")":
                    currentNode = addMoveToTree(currentString)
                    currentString = ""
                    
                    currentNode = variationNodes.last!
                    variationNodes.removeLast()
                    game = Game(position: dictPosition[currentNode]!)
                case " ":
                    currentNode = addMoveToTree(currentString)
                    currentString = ""
                case "\n":
                    // Check if there is an alternate starting fen
                    if let fen = tagPairs["FEN"] {
                        let position = FenSerialization.default.deserialize(fen: fen)
                        if let startingNode = dictBoardNode[position.board] {
                            currentNode = startingNode
                            game = Game(position: position)
                        } else {
                            currentNode = rootNode
                            game = Game(position: startingGamePosition)
                        }
                    } else {
                        currentNode = rootNode
                        game = Game(position: startingGamePosition)
                    }
                    currentString = ""
                case "$":
                    currentNode = addMoveToTree(currentString)
                    currentString = ""
                    nagActive = true
                case ".":
                    currentString = ""
                case "*":
                    currentNode = addMoveToTree(currentString)
                    currentString = ""
                    // Save everything
                    tagPairs = [:]
                default:
                    currentString.append(char)
                }
            case .termination:
                if char == "\n" {
                    currentToken = .unknown
                    currentString = ""
                }
            }
        }
        
        return allNodes

        enum Token {
            case tagPair, comment, unknown, termination
        }
        
        func addMoveToTree(_ rawMove: String) -> GameNode {
            if rawMove.isEmpty { return currentNode }
            if nagActive {
                // Save NAG
                nagActive = false
                return currentNode
            }
            
            let pattern = "\\d-\\d"
            let regex = try! NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: rawMove, range: NSRange(rawMove.startIndex..., in: rawMove))
            
            if !matches.isEmpty { return currentNode }
            
            var newNode = rootNode
            
            if rawMove == "" || rawMove == "\n" {
                print("Alarm")
            }
            var moveString = ""
            var annotation: String = ""
            
            if rawMove.hasSuffix("!?") || rawMove.hasSuffix("?!") || rawMove.hasSuffix("!!") || rawMove.hasSuffix("??") {
                annotation = String(rawMove.suffix(2))
                moveString =  String(rawMove.dropLast(2))
            } else if rawMove.hasSuffix("!") || rawMove.hasSuffix("?") {
                annotation = String(rawMove.suffix(1))
                moveString =  String(rawMove.dropLast())
            } else {
                moveString =  rawMove
            }
            
            let move = SanSerialization.default.move(for: moveString, in: game)
            
            game.make(move: move)
            
            if currentNode.children.contains(where: {$0.moveString==moveString}) {
                newNode = currentNode.children.first(where: {$0.moveString==moveString})!.child
            }
            else if let node = dictNode[game.position] {
                let moveNode = MoveNode(moveString: moveString, move: move, annotation: annotation, child: node, parent: currentNode)
                currentNode.children.append(moveNode)
                newNode = node
                newNode.parents.append(moveNode)
            }
            else {
                let fen = FenSerialization.default.serialize(position: game.position)
                newNode = GameNode(fen: fen)
                
                let moveNode = MoveNode(moveString: moveString, move: move, annotation: annotation, child: newNode, parent: currentNode)
                currentNode.children.append(moveNode)
                newNode.parents.append(moveNode)
                
                allNodes.append(newNode)
                dictNode[game.position] = newNode
                dictPosition[newNode] = game.position
                dictBoardNode[game.position.board] = newNode
            }
            return newNode
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
