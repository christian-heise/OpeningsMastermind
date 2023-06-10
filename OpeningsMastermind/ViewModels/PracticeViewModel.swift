//
//  PractiseViewModel.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 06.05.23.
//

import Foundation
import ChessKit

@MainActor class PracticeViewModel: ParentChessBoardModel, ParentChessBoardModelProtocol {
    
    @Published var selectedGameTrees: Set<GameTree>
    let database: DataBase
    @Published var currentNodes: [GameNode]
    
    init(database: DataBase) {
        self.currentNodes = []
        self.database = database
        self.selectedGameTrees = Set()
        super.init()
        
        self.loadUserDefaults()
        self.reset()
    }
    
    var gameCopy: Game? = nil
    
    @Published var userColor: PieceColor = .white
    
    var annotation: (String?, String?) {
        if currentNodes.count > 1 {
            return (nil, nil)
        } else {
            if let currentNode = currentNodes.first {
                guard let moveNode = currentNode.parents.first(where: {$0.move == moveHistory[positionIndex].0}) else { return (nil, nil) }
                let currentAnnotation = moveNode.annotation
                
                if positionIndex > 0 {
                    guard let oldMoveNode = moveNode.parent?.parents.first(where: {$0.move == moveHistory[positionIndex-1].0}) else { return (nil, nil) }
                    return (currentAnnotation, oldMoveNode.annotation)
                } else {
                    return (currentAnnotation, nil)
                }
            } else {
                return (nil, nil)
            }
        }
    }
    
    func saveUserDefaults() {
        do {
            // Create JSON Encoder
            let encoder = JSONEncoder()
            // Encode Note
            let data = try encoder.encode(self.selectedGameTrees)
            // Write/Set Data
            UserDefaults.standard.set(data, forKey: "selectedGameTrees")
            print("Saved \(self.selectedGameTrees.count) Gametree(s)")
        } catch {
            print("Unable to Encode Note (\(error))")
        }
    }
    func loadUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "selectedGameTrees") {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()
                // Decode Note
                self.selectedGameTrees = try decoder.decode(Set<GameTree>.self, from: data)
                print("Loaded \(self.selectedGameTrees.count) Gametree(s)")
            } catch {
                print("Unable to Decode Note (\(error))")
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
            for moveNode in currentNode.children {
                self.rightMove.append(moveNode.move)
            }
        }
    }
    
    func jump(to index: Int) {}
    
    func onAppear() {
        if self.selectedGameTrees.isEmpty { return }
        
        if self.selectedGameTrees.contains(where: {!database.gametrees.contains($0)}) {
            self.selectedGameTrees = self.selectedGameTrees.filter({database.gametrees.contains($0)})
            self.saveUserDefaults()
            self.reset()
        }
    }
    
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
            
            self.positionHistory.append(self.game.position)
            self.moveHistory.append((newMove!, san))
            self.positionIndex = self.positionIndex + 1
            
            addMistake(0)
            
            self.game.make(move: newMove!)
            if newNode!.children.isEmpty {
                gameState = 2
            }
            var newNodes: [GameNode] = []
            for i in 0..<currentNodes.count {
                if currentNodes[i].children.contains(where: {$0.moveString == san}) {
                    newNodes.append(currentNodes[i].children.first(where: {$0.moveString == san})!.child)
                }
            }
            self.currentNodes = newNodes
        }
    }
    
    override func performMove(_ move: Move) {
        if self.selectedGameTrees.isEmpty { return }
        if !game.legalMoves.contains(move) || gameState > 0 { return }
        
        let potentialNodes = currentNodes.filter({!$0.children.isEmpty}).filter({$0.children.contains(where: {$0.move == move})})
        
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
            if currentNodes[i].children.contains(where: {$0.moveString == san}) {
                newNodes.append(currentNodes[i].children.first(where: {$0.moveString == san})!.child)
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
            let moveNode = node.children.first!
            let generatedMove = moveNode.move
            let newNode = moveNode.child
            return (generatedMove, newNode)
        }
        
        // Probabilities based on Mistakes
        let probabilitiesMistakes = node.children.map({$0.child.mistakesRate / node.children.map({$0.child.mistakesRate}).reduce(0, +)})
        // Probability based on Depth
        let depthArray: [Double] = node.children.map({Double($0.child.depth) * Double($0.child.depth)})
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
                let moveNode = node.children[i]
                let generatedMove = moveNode.move
                let newNode = moveNode.child
                
                return (generatedMove, newNode)
            }
        }
        let moveNode = node.children.first!
        let generatedMove = moveNode.move
        let newNode = moveNode.child
        
        return (generatedMove, newNode)
    }
}
