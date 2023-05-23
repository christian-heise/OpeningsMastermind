//
//  PractiseViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 06.05.23.
//

import Foundation
import ChessKit

@MainActor class PracticeViewModel: ParentChessBoardModel, ParentChessBoardModelProtocol {
    
    var selectedGameTrees: Set<GameTree>
    let database: DataBase
    @Published var currentNodes: [GameNode]
    
    init(database: DataBase) {
        self.currentNodes = []
        self.database = database
        self.selectedGameTrees = Set()
        
        super.init()
        self.reset()
    }
    
    var gameCopy: Game? = nil
    
    @Published var userColor: PieceColor = .white
    
    var annotation: (String?, String?) {
        if currentNodes.count > 1 {
            return (nil, nil)
        } else {
            if let currentNode = currentNodes.first {
                if let parentNode = currentNode.parent {
                    return (currentNode.annotation, parentNode.annotation)
                } else {
                    return (currentNode.annotation, nil)
                }
            } else {
                return (nil, nil)
            }
        }
    }
    
    func revertMove() {
        self.game = gameCopy ?? Game(position: startingGamePosition)
        self.positionHistory.removeLast()
        self.moveHistory.removeLast()
        self.positionIndex = self.positionIndex - 1
        gameState = 0
    }
    
    func determineRightMove() {
        self.rightMove = []
        let decoder = SanSerialization.default
        for currentNode in currentNodes {
            for node in currentNode.children {
                self.rightMove.append(decoder.move(for: node.move, in: self.game))
            }
        }
    }
    
    func jump(to index: Int) {}
    
    func reset() {
        self.game = Game(position: startingGamePosition)
        self.currentNodes = self.selectedGameTrees.map({$0.rootNode})
        self.gameState = -1
        
        self.moveHistory = []
        self.positionHistory = []
        self.positionIndex = -1
        
        if selectedGameTrees.isEmpty { return }
        if self.userColor == .black {
            Task {
                await performComputerMove(in: 0)
            }
        }
    }
    
    func performComputerMove(in time_ms: Int) async {
        let potentialNodes = currentNodes.filter({!$0.children.isEmpty})
        guard let currentNode = potentialNodes.randomElement() else {
            await MainActor.run {
                gameState = 2
            }
            return
        }
        let (newMove, newNode) = generateMove(game: game, node: currentNode)
        
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
            var newNodes: [GameNode] = []
            for i in 0..<currentNodes.count {
                if currentNodes[i].children.contains(where: {$0.move == san}) {
                    newNodes.append(currentNodes[i].children.first(where: {$0.move == san})!)
                }
            }
            self.currentNodes = newNodes
        }
    }
    
    override func performMove(_ move: Move) {
        if self.selectedGameTrees.isEmpty { return }
        if !game.legalMoves.contains(move) || gameState > 0 { return }
        
        let potentialNodes = currentNodes.filter({!$0.children.isEmpty}).filter({
            let (success, _) = $0.databaseContains(move: move, in: game)
            return success
        })
        
        let san = SanSerialization.default.correctSan(for: move, in: game)
        
        guard !potentialNodes.isEmpty else {
            self.gameCopy = self.game.deepCopy()
            if currentNodes.map({$0.children.isEmpty}).contains(where: {!$0}) {
                self.gameState = 1
                determineRightMove()
                game.make(move: move)
                
                self.positionHistory.append(self.game.position)
                self.moveHistory.append((move, san))
                self.positionIndex = self.positionIndex + 1
                
                self.addMistake(1)
            } else {
                gameState = 2
            }
            return
        }
        
        self.positionHistory.append(self.game.position)
        self.moveHistory.append((move, san))
        self.positionIndex = self.positionIndex + 1
        
        addMistake(0)
        var newNodes: [GameNode] = []

        for i in 0..<currentNodes.count {
            if currentNodes[i].children.contains(where: {$0.move == san}) {
                newNodes.append(currentNodes[i].children.first(where: {$0.move == san})!)
            }
        }
        self.currentNodes = newNodes
        self.game.make(move: move)
        gameState = 0
        Task {
            await performComputerMove(in: 300)
        }
    }
    
    func addMistake(_ mistake: Int) {
        for node in currentNodes {
            node.mistakesLast5Moves.removeFirst()
            node.mistakesLast5Moves.append(mistake)
        }
    }
    
    func generateMove(game: Game, node: GameNode) -> (Move?, GameNode?) {
        if node.children.count == 1 {
            let newNode = node.children.first!
            let decoder = SanSerialization.default
            let generatedMove = decoder.move(for: newNode.move, in: game)
            return (generatedMove, newNode)
        }
        
        // Probabilities based on Mistakes
        let probabilitiesMistakes = node.children.map({$0.mistakesRate / node.children.map({$0.mistakesRate}).reduce(0, +)})
        
        
        // Probability based on Depth
        let depthArray: [Double] = node.children.map({Double($0.depth) * Double($0.depth)})
        let summedDepth = depthArray.reduce(0, +)
        
        var probabilitiesDepth = [Double]()
        
        if summedDepth == 0 {
            probabilitiesDepth = Array(repeating: 1 / Double(node.children.count), count: node.children.count)
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
                let newNode = node.children[i]
                let decoder = SanSerialization.default
                let generatedMove = decoder.move(for: newNode.move, in: game)
                
                return (generatedMove, newNode)
            }
        }
        let newNode = node.children.first!
        let decoder = SanSerialization.default
        let generatedMove = decoder.move(for: newNode.move, in: game)
        
        return (generatedMove, newNode)
    }
}
