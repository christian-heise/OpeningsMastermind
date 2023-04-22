//
//  GameTree.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.04.23.
//


import Foundation
import ChessKit

class GameTree: ObservableObject, Identifiable {
    let name: String
    let id = UUID()
    let rootNode: GameNode?
    let userColor: PieceColor
    
    @Published var currentNode: GameNode?
    
    @Published var gameState: Int = 0
    @Published var rightMove: Move? = nil
    
    static let examplePGN = """
    1. e4 c5 2. d4 cxd4 3. c3 dxc3 4. Nxc3 Nc6 { The next three moves drawn by arrows, in any order, lead to the main line position that this chapter will cover. } { [%cal Gb8c6,Ga7a6,Ge7e6] } 5. Nf3 e6 6. Bc4 a6 7. O-O Nge7 (7... b5 8. Bb3 Bb7 (8... Na5 { This variation seems problematic. I want to see the suggestion in the book before I put anything here. }) 9. a4 b4 10. Nd5 { [%cal Ge6d5] } 10... exd5 11. exd5)  (7... Qc7 8. Qe2 Bd6 9. Rd1 Nge7 10. Be3 O-O 11. Qd2 Bb4 12. a3 Bxc3 13. Qxc3)  (7... Nf6)  (7... Be7)  (7... Bc5) 8. Bg5 f6 (8... b5 9. Bxb5 axb5 10. Nxb5 d5 11. Bf4 Ng6 12. Nc7+ Ke7 13. Bg3 Ra7 14. exd5 e5 15. Nb5 Rd7 16. Qc2 Rxd5 (16... Nb4 17. Qe4) 17. Qxc6)  (8... h6 9. Be3 b5)  (8... d6 9. Qe2)  (8... Qc7 { Another natural move besides either pawn move. But black doesn't expect this... } 9. Nd5!! exd5 (9... Nxd5 10. exd5 Ne5 11. Bb3 Nxf3+ 12. Qxf3 Bd6 13. dxe6 dxe6 (13... fxe6 14. Rac1 Qa5 15. h4) 14. Ba4+) 10. exd5 Ne5 11. d6!! { The bishop is largely unimportant considering what black is about to be put through. } 11... Nxf3+ 12. Qxf3 Qxc4 (12... Qxd6?? 13. Bxf7+ Kd8 14. Rac1 $18) 13. Rfe1 f6 14. Rac1 Qxa2 15. Bxf6 Qf7 (15... gxf6 16. Qxf6 Qf7 (16... Rg8 17. Rxe7+ Kd8 18. Re6+ Be7 19. Qxe7#) 17. Qxh8) 16. dxe7 Qxf6 17. exf8=Q+ Kxf8 18. Qh5 g6 19. Qh6+ Kf7 20. Rc3 Qg7 21. Rf3+ Qf6 22. Rxf6+ Kxf6 23. Qf4+ Kg7 24. Re7+ Kg8 25. Qf7#) 9. Be3 b5 (9... Ng6) 10. Bb3 Ng6 (10... Na5 11. Nd4 Nxb3 12. Qxb3 Bb7 13. Rfd1 { [%cal Gd4e6] } 13... Qb8 14. Rac1 Nc6 15. Ncxb5 axb5 16. Nxc6 Bxc6 17. Rxc6 dxc6 18. Qxe6+ Be7 19. Rd7) 11. Nd5 { Threatens Bb6. trapping black's queen. This is a very thematic sacrifice within this opening, as the opening of the e file that would come with taking the knight is legitimately worth a full piece. } { [%csl Ge7,Gb6,Gc7,Gd8][%cal Ge3b6,Gb6d8,Gd5e7] } 11... Rb8 { Rb8 wisely avoids the complications involved with taking the knight, and instead covers the b6 square to prevent Bb6 } (11... exd5 12. exd5 Nce5 (12... Na5 { While it doesn't look that bad, this move loses for black. The e-file pressure that's on its way is such a big deal that black can't afford not to put the knight there. } 13. Re1 { [%csl Gd8][%cal Ge3b6,Ge1e8,Gb6d8] } 13... Be7 14. d6 Nxb3 15. axb3 Bb7 16. dxe7 Qc7 17. Rc1 Bc6 18. Nd4) 13. d6 { This move is necessary because if black is allowed to play Bd6, with out pawn on d5, they can escape our e file pressure and simply be up a piece. } (13. Re1?? Bd6 14. Nxe5 fxe5 15. f4 O-O 16. fxe5 Nxe5 $19) 13... Bb7 (13... Nxf3+ { Allowing us to take back with a tempo on the rook, combined with the pressure we can quickly put down the e file makes this trade losing for black. } 14. Qxf3 Rb8 15. Rfe1 { [%csl Gb6][%cal Ge3b6,Gb6d8,Ge1e8] }) 14. Nxe5 fxe5 (14... Nxe5 { This move leads to an unstoppable attack for white with pressure down the e file. } 15. Re1 Qb8 16. Bc5 { [%csl Gd6][%cal Gf2f4,Gc5d6] } 16... Kd8 17. Qd4 a5 18. f4 Ng6 (18... Ra6 19. Bb6+ Kc8 20. Rac1+ Bc6 21. Rxc6+ Nxc6 22. Re8+ Kb7 23. Rxb8+ Kxb8 24. Bc7+ Kc8 25. Qc5 b4 26. Bc4) 19. Bb6+ Kc8 20. Re8#) 15. f4 exf4 { Bxf4 allows Qb6+ and queenside castles, and black makes it out alive. Rxf4 blunders an extra exchange. So... we sac another piece! } (15... Qf6)  (15... e4) 16. Re1 fxe3 (16... Ne5 17. Qh5+ Ng6 18. Bb6+) 17. Rxe3+ Be7 18. Qd4 Qc8 { Desperately makes a getaway square for the king as a big attack is on the way. } (18... Qb8 19. dxe7 Qa7 20. Bf7+ Kxf7 21. e8=Q+ Rhxe8 22. Rf1+ Kg8 23. Rxe8+ Rxe8 24. Qxa7) 19. Rf1 { [%csl Gf7][%cal Gb3f7] } 19... Qc6 { [%csl Gg2][%cal Gc6g2] } 20. Re2 Kd8 21. dxe7+ Nxe7 22. Qe3 { [%cal Ge3e7] } 22... Re8 23. Bf7 Rf8 24. Qxe7+ Kc7)  (11... Bb7 12. Bb6 Qc8 13. Nc7+ Kf7 14. Nxa8 Bxa8 15. Rc1 Be7 16. Nd4 Re8 17. Nf5) 12. Rc1 { Black finds it very difficult to move anything here. All other moves fail (and some common ones will be analyzed here) except for a5, with the plan of expanding on the queenside since there's not much else to do. } 12... a5 { You can learn the main line with a3 and Ba2, but I actually suggest a novelty. } (12... Be7)  (12... exd5)  (12... Kf7)  (12... Nge5) 13. h4! $146 { [%cal Gh4h5] } 13... a4 (13... h5 14. Nf4 Nce5 15. Nxg6 Nxg6 16. Qe2 { [%cal Gf1d1] } 16... a4 17. Bc2 Be7 18. Rfd1 O-O 19. e5 f5 20. Ng5 { [%csl Gh5][%cal Ge2h5] } 20... Bxg5 21. Bxg5 Qb6 22. Qxh5 Nxe5 23. Be3 Qa6) 14. Bc2 Kf7 { Black is finally threatening to take our knight while being able to survive the complications. } (14... exd5 15. exd5 Nce5 16. Nxe5 Nxe5 17. f4 Nf7 18. Re1 Be7 19. d6 Nxd6 20. Bc5 O-O 21. Rxe7 Qxe7 22. Qd3 { disallowing Qe3+ after Bxd6 and threatening h7 } 22... f5 (22... g6 23. Bxd6 Qe6 24. f5 gxf5 (24... Qxf5 25. Qxf5 gxf5 26. Bxb8) 25. Qg3+ Kf7 26. Bxb8 Qb6+ 27. Kh2) 23. Bxd6 Qe6 24. Bxf8 Kxf8 25. Qxf5+ Qxf5 26. Bxf5)  (14... Nge5 15. Nxe5 Nxe5 16. Ba7 { Forcing Rb7 to stop Bb7 } 16... Rb7 (16... Ba6 17. Bxb8 Qxb8) 17. Bd4) 15. Nf4 Bb7 16. h5 Nge5 (16... Nxf4 17. Bxf4 Rc8) 17. Nd3 { Threatens to take twice on e5 and play f5, opening up towards black's king } 17... Nc4 18. Bf4 e5 19. Bg3 d5 20. Re1 dxe4 21. Rxe4 Bd6 22. b3 *
    """
    
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
        
        let randomInt = Int.random(in: 0..<currentNode.children.count)
        
        let decoder = SanSerialization.default
        let newGameNode = currentNode.children[randomInt]
        let generatedMove = decoder.move(for: newGameNode.move, in: game)
        return (generatedMove, newGameNode)
    }
    
    func reset() {
        self.currentNode = self.rootNode
        self.gameState = 0
        self.rightMove = nil
    }
    
    static private func decodePGN(pgnString: String) -> GameNode? {
        
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
                guard let lastVariationStart = variationStart.last else {return nil}
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
