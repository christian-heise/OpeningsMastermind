//
//  PracticeCenterViewModel.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 16.06.23.
//

import Foundation


class PracticeCenterViewModel: ObservableObject {
    let database: DataBase
    
    @Published var queueItems: [QueueItem] = []
    
    init(database: DataBase) {
        self.database = database
    }
    
    func getQueueItems() {
        var storedNodes = [QueueItem]()
        for tree in database.gametrees {
            // Add Nodes which repeat date is due
            var nodes = tree.allGameNodes.filter({$0.dueDate <= Date() && !$0.mistakesLast5Moves.isEmpty && $0.nextMoveColor == tree.userColor})
            // If no Node is due: Add Nodes which haven't been explored
            if nodes.isEmpty {
                nodes = tree.allGameNodes.filter({$0.mistakesLast5Moves.isEmpty && !$0.children.isEmpty && $0.nextMoveColor == tree.userColor})
            }
            storedNodes.append(contentsOf: nodes.prefix(2).map({QueueItem(gameNode: $0, gameTree: tree)}))
        }
        storedNodes.sort(by: {
            return $0.gameNode.nodesBelow > $1.gameNode.nodesBelow })
        self.queueItems = storedNodes
    }
}

struct QueueItem: Identifiable {
    let gameNode: GameNode
    let gameTree: GameTree
    
    var id: UUID {
        return self.gameNode.id
    }
}
