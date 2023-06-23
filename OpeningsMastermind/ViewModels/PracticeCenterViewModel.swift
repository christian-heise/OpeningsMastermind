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
//            print("\(tree.name) has \(tree.allGameNodes.count) nodes")
//            let crossReference = Dictionary(grouping: tree.allGameNodes, by: \.fen)
//            let duplicates = crossReference
//                .filter { $1.count > 1 }
//            print(duplicates.count)
            // Add Nodes which repeat date is due
            var nodes = Array(tree.allGameNodes.filter({$0.dueDate <= Date() && !$0.mistakesLast5Moves.isEmpty}))
            // If no Node is due: Add Nodes which haven't been explored
            if nodes.isEmpty {
                nodes = tree.allGameNodes.filter({$0.mistakesLast5Moves.isEmpty && !$0.children.isEmpty && $0.nextMoveColor == tree.userColor})
            }
            nodes.sort(by: { return $0.nodesBelow > $1.nodesBelow
//                if $0.mistakesSum == $1.mistakesSum {
//                    return $0.nodesBelow < $1.nodesBelow
//                } else {
//                    return $0.mistakesSum > $1.mistakesSum
//                }
            })
            storedNodes.append(contentsOf: nodes.prefix(2).map({QueueItem(gameNode: $0, gameTree: tree)}))
        }
        storedNodes.sort(by: {
            return $0.gameNode.nodesBelow > $1.gameNode.nodesBelow
//            if $0.gameNode.mistakesSum == $1.gameNode.mistakesSum {
//                return $0.gameNode.nodesBelow < $1.gameNode.nodesBelow
//            } else {
//                return $0.gameNode.mistakesSum > $1.gameNode.mistakesSum
//            }
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
