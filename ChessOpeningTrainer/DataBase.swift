//
//  DataBase.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import Foundation
import ChessKit


class DataBase: ObservableObject {
    let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @Published var gametrees: [GameTree] = []
    
    
    private func save() {
        
    }
    
    func load() {
        
    }
    
    func addNewGameTree(_ gameTree: GameTree) {
        self.gametrees.append(gameTree)
        self.save()
    }
    
    func addNewGameTree(name: String, pgnString: String, userColor: PieceColor) {
        self.gametrees.append(GameTree(name: name, pgnString: pgnString, userColor: userColor))
        self.save()
    }
    
    func addExampleGameTree() {
        self.gametrees.append(GameTree.example())
        self.save()
    }
    
    func removeGameTree(at offsets: IndexSet) {
        self.gametrees.remove(atOffsets: offsets)
    }
}
