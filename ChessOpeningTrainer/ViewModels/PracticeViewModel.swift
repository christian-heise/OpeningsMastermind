//
//  PractiseViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 06.05.23.
//

import Foundation
import ChessKit

@MainActor class PracticeViewModel: ParentChessBoardModel, ParentChessBoardModelProtocol {
    @Published var currentNode: GameNode
    let gameTree: GameTree
    
    init(gameTree: GameTree) {
        self.currentNode = gameTree.rootNode
        self.gameTree = gameTree
        super.init()
    }
    
    var gameCopy: Game? = nil
    
    var userColor: PieceColor {
        self.gameTree.userColor
    }
    
    var annotation: (String?, String?) {
        if let parentNode = currentNode.parent {
            return (currentNode.annotation, parentNode.annotation)
        } else {
            return (currentNode.annotation, nil)
        }
    }
    
    func revertMove() {
        self.game = gameCopy ?? Game(position: startingGamePosition)
        self.positionHistory.removeLast()
        self.moveHistory.removeLast()
        self.positionIndex = self.positionIndex - 1
        gameState = 0
        objectWillChange.send()
    }
    
    func determineRightMove() {
        self.rightMove = []
        let decoder = SanSerialization.default
        for node in currentNode.children {
            self.rightMove.append(decoder.move(for: node.move, in: self.game))
        }
    }
    
    func jump(to index: Int) {}
    
    func reset() {
        self.game = Game(position: startingGamePosition)
        self.currentNode = gameTree.rootNode
//        self.moveStringList = []
        self.gameState = 0
        
        self.moveHistory = []
        self.positionHistory = []
        self.positionIndex = -1
        
        if self.userColor == .black {
            Task {
                await performComputerMove(in: 0)
            }
        } else {
            objectWillChange.send()
        }
    }
    
    func performComputerMove(in time_ms: Int) async {
        if currentNode.children.isEmpty {
            await MainActor.run {
                gameState = 2
                objectWillChange.send()
            }
            return
        }
        let (newMove, newNode) = generateMove(game: game)
        
        try? await Task.sleep(for: .milliseconds(time_ms))
        
        await MainActor.run {
            let san = SanSerialization.default.correctSan(for: newMove!, in: self.game)

//            self.moveStringList.append(san)
            self.positionHistory.append(self.game.position)
            self.moveHistory.append((newMove!, san))
            self.positionIndex = self.positionIndex + 1
            
            self.game.make(move: newMove!)
            if newNode!.children.isEmpty {
                gameState = 2
            }
            currentNode = newNode!
            objectWillChange.send()
        }
    }
    
    override func performMove(_ move: Move) {
        if !game.legalMoves.contains(move) || gameState != 0 { return }
        
        let (success, newNode) = currentNode.databaseContains(move: move, in: self.game)
        
        self.positionHistory.append(self.game.position)
        self.moveHistory.append((move, SanSerialization.default.correctSan(for: move, in: game)))
        self.positionIndex = self.positionIndex + 1
        
        if success {
            addMistake(0)
            currentNode = newNode
//            self.moveStringList.append(SanSerialization.default.correctSan(for: move, in: self.game))
            self.game.make(move: move)
            gameState = 0
            Task {
                await performComputerMove(in: 300)
            }
        } else {
            self.gameCopy = self.game.deepCopy()
            if !currentNode.children.isEmpty {
                addMistake(1)
                self.gameState = 1
                
                determineRightMove()
                game.make(move: move)
                
            } else {
                print("Hä")
                gameState = 2
            }
            objectWillChange.send()
        }
    }
    func processPromotion(_ kind: PieceKind) {
        guard let promotionMove = self.promotionMove else { return }
        self.promotionMove = nil
        performMove(Move(from: promotionMove.from, to: promotionMove.to, promotion: kind))
    }
    
    func addMistake(_ mistake: Int) {
        currentNode.mistakesLast5Moves.removeFirst()
        currentNode.mistakesLast5Moves.append(mistake)
    }
    
    func generateMove(game: Game) -> (Move?, GameNode?) {
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
}
