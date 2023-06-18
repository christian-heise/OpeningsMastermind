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
            var nodes = tree.allGameNodes.filter({$0.dueDate <= Date() && !$0.mistakesLast5Moves.isEmpty})
            nodes.sort(by: {
                if $0.mistakesSum == $1.mistakesSum {
                    return $0.nodesBelow < $1.nodesBelow
                } else {
                    return $0.mistakesSum > $1.mistakesSum
                }
            })
            storedNodes.append(contentsOf: nodes.prefix(2).map({QueueItem(gameNode: $0, gameTree: tree)}))
        }
        storedNodes.sort(by: {
            if $0.gameNode.mistakesSum == $1.gameNode.mistakesSum {
                return $0.gameNode.nodesBelow < $1.gameNode.nodesBelow
            } else {
                return $0.gameNode.mistakesSum > $1.gameNode.mistakesSum
            }
        })
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
