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
    
    var queueItems: [QueueItem] = []
    var currentQueueIndex: Int = 0
    
    var userColor: PieceColor = .white
    
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
    var currentMoveColor: PieceColor {
        guard let previousColor = currentNodes.first?.parents.first?.moveColor else { return .white}
        
        return previousColor == .white ? .black : .white
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
    
    func determineRightMove() {
        self.rightMove = []
        for currentNode in currentNodes {
            for moveNode in currentNode.children {
                self.rightMove.append(moveNode.move)
            }
        }
    }
    
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
        self.gameState = .practice
        
        self.userColor = selectedGameTrees.first?.userColor ?? .white
        
        self.moveHistory = []
        self.positionHistory = []
        self.positionIndex = -1
        
        self.promotionMove = nil
        self.promotionPending = false
        
        if selectedGameTrees.isEmpty { return }
        if self.userColor == currentNodes.first?.parents.first?.moveColor ?? .black {
            Task {
                await performComputerMove(in: 0)
            }
        }
    }
    
    func performComputerMove(in time_ms: Int) async {
        let potentialNodes = currentNodes.filter({!$0.children.isEmpty})
        guard let currentNode = potentialNodes.randomElement() else {
            await MainActor.run {
                gameState = .endOfLine
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
            
            addMistake(false)
            
            self.game.make(move: newMove!)
            if newNode!.children.isEmpty {
                gameState = .endOfLine
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
        if !game.legalMoves.contains(move) || gameState == .mistake || gameState == .endOfLine { return }
        
        let potentialNodes = currentNodes.filter({!$0.children.isEmpty}).filter({$0.children.contains(where: {$0.move == move})})
        
        let san = SanSerialization.default.correctSan(for: move, in: game)
        
        guard !potentialNodes.isEmpty else {
            if currentNodes.map({$0.children.isEmpty}).contains(where: {!$0}) {
                self.gameState = .mistake
                determineRightMove()
                self.positionHistory.append(self.game.position)
                game.make(move: move)
                self.moveHistory.append((move, san))
                self.positionIndex += 1
                
                self.addMistake(true)
            } else {
                gameState = .endOfLine
            }
            return
        }
        
        self.positionHistory.append(self.game.position)
        self.moveHistory.append((move, san))
        self.positionIndex = self.positionIndex + 1
        
        addMistake(false)
        var newNodes: [GameNode] = []

        for i in 0..<currentNodes.count {
            if currentNodes[i].children.contains(where: {$0.moveString == san}) {
                newNodes.append(currentNodes[i].children.first(where: {$0.moveString == san})!.child)
            }
        }
        self.currentNodes = newNodes
        self.game.make(move: move)
        gameState = .practice
        Task {
            await performComputerMove(in: 300)
        }
    }
    
    func forwardMove() {
        guard self.positionIndex + 1 < self.positionHistory.count else { return }
        self.positionIndex += 1
        self.game.make(move: self.moveHistory[positionIndex].0)
        
        if self.positionIndex + 1 == self.positionHistory.count {
            self.gameState = .practice
        } else {
            self.objectWillChange.send()
        }
    }
    
    func reverseMove() {
        if self.gameState == .mistake {
            self.game = Game(position: positionHistory[positionIndex], moves: Array(self.game.movesHistory.prefix(positionIndex)))
            self.positionHistory.removeLast()
            self.moveHistory.removeLast()
            self.positionIndex -= 1
            gameState = .practice
        } else {
            guard self.positionIndex >= 0 else {return}
            
            self.game = Game(position: positionHistory[positionIndex], moves: Array(self.game.movesHistory.prefix(positionIndex)))
            self.positionIndex -= 1
            
            self.gameState = .idle
        }
    }
    
    func jump(to index: Int) {
        if index == positionIndex {
            print("Same Index")
            return
        } else if index > positionIndex {
            for _ in 0..<(index - positionIndex) {
                forwardMove()
            }
        } else {
            for _ in 0..<(positionIndex - index) {
                reverseMove()
            }
        }
    }
    
    func addMistake(_ mistake: Bool) {
        for node in currentNodes {
            if node.mistakesLast5Moves.count == 5, let earliestDate = node.mistakesLast5Moves.keys.min() {
                node.mistakesLast5Moves.removeValue(forKey: earliestDate)
            }
            node.mistakesLast5Moves[Date()] = mistake
        }
        self.database.objectWillChange.send()
        for tree in self.selectedGameTrees {
           tree.dateLastPlayed = Date()
        }
    }
    
    func generateMove(game: Game, node: GameNode) -> (Move?, GameNode?) {
        if node.children.isEmpty { return (nil,nil)}
        
        if node.children.count == 1 {
            let moveNode = node.children.first!
            let generatedMove = moveNode.move
            let newNode = moveNode.child
            return (generatedMove, newNode)
        }
        
        var probabilities: [Double] = []
        
        // Candidate Moves
        var moveNodeCandidates = node.children
        
        if moveNodeCandidates.contains(where: {$0.child.lastTryWasMistake}) {
            moveNodeCandidates = moveNodeCandidates.filter({$0.child.lastTryWasMistake})
            
            // Probability based on Nodes Below
            let depthArray: [Double] = moveNodeCandidates.map({Double($0.child.nodesBelow)})
            let summedDepth = depthArray.reduce(0, +)

            if summedDepth == 0 {
                probabilities = Array(repeating: 1 / Double(moveNodeCandidates.count), count: moveNodeCandidates.count)
            } else {
                probabilities = depthArray.map({$0 / Double(summedDepth)})
            }
        } else if moveNodeCandidates.contains(where: {$0.child.dueDate < Date()}) {
            moveNodeCandidates = moveNodeCandidates.filter({$0.child.dueDate < Date()})
            // Probability based on Nodes Below
            let depthArray: [Double] = moveNodeCandidates.map({Double($0.child.nodesBelow)})
            let summedDepth = depthArray.reduce(0, +)

            if summedDepth == 0 {
                probabilities = Array(repeating: 1 / Double(moveNodeCandidates.count), count: moveNodeCandidates.count)
            } else {
                probabilities = depthArray.map({$0 / Double(summedDepth)})
            }
        } else {
            // Probability based on Nodes Below
            let depthArray: [Double] = moveNodeCandidates.map({Double($0.child.nodesBelow)})
            let summedDepth = depthArray.reduce(0, +)

            if summedDepth == 0 {
                probabilities = Array(repeating: 1 / Double(moveNodeCandidates.count), count: moveNodeCandidates.count)
            } else {
                probabilities = depthArray.map({$0 / Double(summedDepth)})
            }
        }

        probabilities = probabilities.map({$0 / probabilities.reduce(0,+)})

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
    
    func initializeQueueItem(queueItem: QueueItem) {
        self.currentNodes = [queueItem.gameNode]
        self.selectedGameTrees = Set([queueItem.gameTree])
        self.game = Game(position: FenSerialization.default.deserialize(fen: queueItem.gameNode.fen))
        self.gameState = .practice
        self.userColor = queueItem.gameTree.userColor
        
        var moveHistory: [(Move, String)] = []
        var positionHistory: [Position] = []
        var currentNode = queueItem.gameNode
        
        while true {
            guard let parentMove = currentNode.parents.first  else { break }
            moveHistory.insert((parentMove.move, parentMove.moveString), at: 0)
            guard let parentNode = parentMove.parent else {
                moveHistory = []
                positionHistory = []
                break
            }
            positionHistory.insert(FenSerialization.default.deserialize(fen: parentNode.fen), at: 0)
            currentNode = parentNode
        }
        self.moveHistory = moveHistory
        self.positionHistory = positionHistory
        self.positionIndex = (queueItem.gameNode.parents.first?.halfMoveNumber ?? 0) - 1
        
        self.currentQueueIndex = self.queueItems.firstIndex(where: {$0.id == queueItem.id}) ?? 0
    }
    
    func nextQueueItem() {
        guard queueItems.count > currentQueueIndex + 1  else { return }
        currentQueueIndex += 1
        initializeQueueItem(queueItem: queueItems[currentQueueIndex])
    }
}
