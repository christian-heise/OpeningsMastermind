//
//  decodePGN.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import Foundation

extension GameTree {
    static func decodePGN(pgnString: String) -> GameNode {
        
        let chapters = pgnString.split(separator: "\n\n").filter({$0.hasPrefix("1.")})
        
        let rootNode = GameNode(moveString: "")
        
        var currentNode = rootNode
        var newNode = rootNode
        
        var variationNodes: [GameNode] = []
        
        var commentActive = false
        
        var comment: String = ""
        
        for i in 0..<chapters.count {
//            let pgnWithoutComments = regex.stringByReplacingMatches(in: String(chapters[i]), options: [], range: NSRange(location: 0, length: chapters[i].utf16.count), withTemplate: "")
            let pgnWithoutComments = String(chapters[i])
            
            let rawMoves = pgnWithoutComments.components(separatedBy: " ").filter({$0 != ""})
            
            print(rawMoves)
            
            currentNode = rootNode

            for rawMove in rawMoves {
                var modifiedString = rawMove
                
                if modifiedString.hasPrefix("{") {
                    commentActive = true
                    modifiedString = String(modifiedString.dropFirst())
                    if modifiedString.isEmpty {
                        continue
                    }
                }
                
                if modifiedString.contains("}") {
                    let rest = modifiedString.split(separator: "}")
                    if rest.count == 2 {
                        comment.append(String(rest.first!))
                        finishComment()
                        modifiedString = String(rest.last!)
                    } else if rest.count == 1 {
                        if modifiedString.hasPrefix("}") {
                            modifiedString = String(modifiedString.dropFirst())
                            finishComment()
                        } else if modifiedString.hasSuffix("}") {
                            modifiedString = String(modifiedString.dropLast())
                            comment.append(String(rest.first!))
                            finishComment()
                            continue
                        } else {
                            print("Whaaaat")
                        }
                    } else if rest.count == 0 {
                        finishComment()
                        continue
                    } else {
                        print("Really Whaaat")
                    }
                }
                
                if commentActive {
                    comment.append(modifiedString + " ")
                    continue
                }
                
                if isMoveNumberWhite(modifiedString) {
                    continue
                } else if isMoveNumberBlack(modifiedString) {
                    continue
                }
                if isVariationMoveNumber(modifiedString) {
                    variationNodes.append(currentNode)
                    currentNode = currentNode.parent!
                    continue
                }
                if modifiedString.hasSuffix(")") {
                    var modifiedMove = modifiedString
                    while modifiedMove.hasSuffix(")") {
                        modifiedMove = String(modifiedMove.dropLast())
                        if !modifiedMove.isEmpty && !modifiedMove.hasPrefix("$") && !modifiedMove.hasSuffix(")") {
                            currentNode = addMoveToTree(modifiedMove)
                        }
                        currentNode = variationNodes.last!
                        variationNodes.removeLast()
                    }
                } else if modifiedString == "*" {
                    continue
                } else if modifiedString == "1-0" || modifiedString == "0-1"{
                continue
                } else if modifiedString.hasPrefix("$") {
                 continue
                } else {
                    currentNode = addMoveToTree(modifiedString)
                }
            }
        }
        
        return rootNode
        
        func finishComment() {
            commentActive = false
            if currentNode.comment == nil {
                currentNode.comment = comment
            } else {
                currentNode.comment!.append("\n" + comment)
            }
            comment = ""
        }
        
        func addMoveToTree(_ rawMove: String) -> GameNode {
            var move = ""
            var annotation: String = ""
            
            if rawMove.hasSuffix("!?") || rawMove.hasSuffix("?!") || rawMove.hasSuffix("!!") || rawMove.hasSuffix("??") {
                annotation = String(rawMove.suffix(2))
                move =  String(rawMove.dropLast(2))
            } else if rawMove.hasSuffix("!") || rawMove.hasSuffix("?") {
                annotation = String(rawMove.suffix(1))
                move =  String(rawMove.dropLast())
            } else {
                move =  rawMove
            }
            
            if move == ")" {
                print("whaaat")
            }
            if !currentNode.children.contains(where: {$0.move==move}) {
                newNode = GameNode(moveString: move, annotation: annotation, parent: currentNode)
                currentNode.children.append(newNode)
            } else {
                newNode = currentNode.children.first(where: {$0.move==move})!
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
    
    
//    static func decodePGNnew(pgnString: String) -> GameNode {
//        let chapters = pgnString.split(separator: "\n\n").filter({$0.hasPrefix("1.")})
//        let rootNode = GameNode(moveString: "")
//
//        var currentNode = rootNode
//        var newNode = rootNode
//
//        var currentPartType: PGNpartType = .number
//
//        for i in 0..<chapters.count {
//            currentNode = rootNode
//        }
//
//
//
//
//
//
//
//
//
//        return GameNode(moveString: "efsfs")
//    }
//
//    enum PGNpartType {
//        case comment, move, number, annotation
//    }
}
