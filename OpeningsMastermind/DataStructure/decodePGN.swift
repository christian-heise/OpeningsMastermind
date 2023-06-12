////
////  decodePGN.swift
////  ChessOpeningTrainer
////
////  Created by Christian Gleißner on 24.04.23.
////
//
//import Foundation
//import ChessKit
//
//extension GameTree {
//    static func decodePGN(pgnString: String) -> GameNode {
//        
//        var game = Game(position: startingGamePosition)
//        
//        let chapters = pgnString.split(separator: "\n\n\n", omittingEmptySubsequences: true)
//
//        let rootNode = GameNode()
//        var currentNode = rootNode
//        
//        var variationNodes: [GameNode] = []
//        
//        var commentActive = false
//        
//        var comment: String = ""
//        
//        var dictPosition: [GameNode: Board] = [rootNode:startingGamePosition.board]
//        var dictNode: [Board: GameNode] = [startingGamePosition.board:rootNode]
//        
//        var boardPosition: [Board: Position] = [startingGamePosition.board:startingGamePosition]
//        
//        for i in 0..<chapters.count {
//            let chapter = String(chapters[i])
//            if let fenRange = chapter.range(of: "\\[FEN \"[^\"]+\"\\]", options: .regularExpression) {
//                let fenString = String(chapter[fenRange])
//                let fen = fenString.replacingOccurrences(of: "[FEN \"", with: "").replacingOccurrences(of: "\"]", with: "")
//                if fen != startingFEN {
//                    let position = FenSerialization.default.deserialize(fen: fen)
//                    if let startingNode = dictNode[position.board] {
//                        currentNode = startingNode
//                        game = Game(position: position)
//                    } else {
//                        continue
//                    }
//                } else {
//                    currentNode = rootNode
//                    game = Game(position: startingGamePosition)
//                }
//            } else {
//                currentNode = rootNode
//                game = Game(position: startingGamePosition)
//            }
//            
//            guard let range = chapter.range(of: "(?<=\\n|^)1\\.", options: .regularExpression) else { continue }
//            let pgnChapter = String(chapter[range.lowerBound...])
//            let rawMoves = pgnChapter.components(separatedBy: .whitespacesAndNewlines).filter({$0 != ""})
//            
//            for rawMove in rawMoves {
//                var modifiedString = rawMove
//                
//                if modifiedString.hasPrefix("{") {
//                    commentActive = true
//                    modifiedString = String(modifiedString.dropFirst())
//                    if modifiedString.isEmpty {
//                        continue
//                    }
//                }
//                
//                if modifiedString.contains("}") {
//                    let rest = modifiedString.split(separator: "}")
//                    if rest.count == 2 {
//                        comment.append(String(rest.first!))
//                        finishComment()
//                        modifiedString = String(rest.last!)
//                    } else if rest.count == 1 {
//                        if modifiedString.hasPrefix("}") {
//                            modifiedString = String(modifiedString.dropFirst())
//                            finishComment()
//                        } else if modifiedString.hasSuffix("}") {
//                            modifiedString = String(modifiedString.dropLast())
//                            comment.append(String(rest.first!))
//                            finishComment()
//                            continue
//                        } else {
//                            print("Whaaaat")
//                        }
//                    } else if rest.count == 0 {
//                        finishComment()
//                        continue
//                    } else {
//                        print("Really Whaaat")
//                    }
//                }
//                
//                if commentActive {
//                    comment.append(modifiedString + " ")
//                    continue
//                }
//                
//                if isMoveNumberWhite(modifiedString) {
//                    continue
//                } else if isMoveNumberBlack(modifiedString) {
//                    continue
//                }
//                
//                if isVariationMoveNumber(modifiedString) {
//                    variationNodes.append(currentNode)
//                    currentNode = currentNode.parents.last!.parent!
//                    game = Game(position: boardPosition[dictPosition[currentNode]!]!)
//                    continue
//                }
//                if modifiedString.hasSuffix(")") {
//                    var modifiedMove = modifiedString
//                    while modifiedMove.hasSuffix(")") {
//                        modifiedMove = String(modifiedMove.dropLast())
//                        if !modifiedMove.isEmpty && !modifiedMove.hasPrefix("$") && !modifiedMove.hasSuffix(")") {
//                            currentNode = addMoveToTree(modifiedMove)
//                            
//                            currentNode = variationNodes.last!
//                            variationNodes.removeLast()
//                            
//                            game = Game(position: boardPosition[dictPosition[currentNode]!]!)
//                        } else if modifiedMove.isEmpty || (modifiedMove.hasPrefix("$") && !modifiedMove.hasSuffix(")")) {
//                            currentNode = variationNodes.last!
//                            variationNodes.removeLast()
//                            game = Game(position: boardPosition[dictPosition[currentNode]!]!)
//                        } else {
//                            variationNodes.removeLast()
//                        }
//                    }
//                } else if modifiedString == "*" {
//                    continue
//                } else if modifiedString == "1-0" || modifiedString == "0-1"{
//                continue
//                } else if modifiedString.hasPrefix("$") {
//                 continue
//                } else {
//                    currentNode = addMoveToTree(modifiedString)
//                }
//            }
//        }
//        
//        return rootNode
//        
//        func finishComment() {
//            commentActive = false
//            if currentNode.comment == nil {
//                currentNode.comment = comment
//            } else {
//                currentNode.comment!.append("\n" + comment)
//            }
//            comment = ""
//        }
//        
//        func addMoveToTree(_ rawMove: String) -> GameNode {
//            var newNode = rootNode
//            
//            if rawMove == "" || rawMove == "\n" {
//                print("Alarm")
//            }
//            var moveString = ""
//            var annotation: String = ""
//            
//            if rawMove.hasSuffix("!?") || rawMove.hasSuffix("?!") || rawMove.hasSuffix("!!") || rawMove.hasSuffix("??") {
//                annotation = String(rawMove.suffix(2))
//                moveString =  String(rawMove.dropLast(2))
//            } else if rawMove.hasSuffix("!") || rawMove.hasSuffix("?") {
//                annotation = String(rawMove.suffix(1))
//                moveString =  String(rawMove.dropLast())
//            } else {
//                moveString =  rawMove
//            }
//            
//            if moveString == ")" {
//                print("whaaat")
//            }
//            
//            let move = SanSerialization.default.move(for: moveString, in: game)
//            
//            game.make(move: move)
//            
//            if currentNode.children.contains(where: {$0.moveString==moveString}) {
//                newNode = currentNode.children.first(where: {$0.moveString==moveString})!.child
//            }
////            else if let node = dictNode[game.position.board] {
////                let moveNode = MoveNode(moveString: moveString, move: move, annotation: annotation, child: node, parent: currentNode)
////                currentNode.children.append(moveNode)
////                newNode = node
////                newNode.parents.append(moveNode)
////            }
//            else {
//                newNode = GameNode()
//                
//                let moveNode = MoveNode(moveString: moveString, move: move, annotation: annotation, child: newNode, parent: currentNode)
//                currentNode.children.append(moveNode)
//                newNode.parents.append(moveNode)
//                
//                dictNode[game.position.board] = newNode
//                dictPosition[newNode] = game.position.board
//                boardPosition[game.position.board] = game.position
//            }
//            return newNode
//        }
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
//}
