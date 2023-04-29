//
//  DataBase.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import Foundation
import ChessKit

let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
let startingGamePosition = FenSerialization.default.deserialize(fen: startingFEN)

class DataBase: ObservableObject, Codable {
    private var appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @Published var gametrees: [GameTree] = []
    
    init() {
        load()
    }
    
    init(gameTrees: [GameTree]) {
        self.gametrees = gameTrees
    }
    
    private func save() {
        let filename = getDocumentsDirectory().appendingPathComponent("gameTree.json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            try data.write(to: filename)
        } catch {
            print("Can not save database")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func load() {
        let filename = getDocumentsDirectory().appendingPathComponent("gameTree.json")
        do {
            let data = try Data(contentsOf: filename)
            let decoder = JSONDecoder()
            let database = try decoder.decode(DataBase.self, from: data)
            self.appVersion = database.appVersion
            self.gametrees = database.gametrees
        } catch {
            print("Could not load database")
        }
    }
    
    func addNewGameTree(_ gameTree: GameTree) {
        self.gametrees.append(gameTree)
        self.save()
    }
    
    func addNewGameTree(name: String, pgnString: String, userColor: PieceColor) -> Bool {
        let newGameTree = GameTree(name: name, pgnString: pgnString, userColor: userColor)
        
        if !newGameTree.rootNode.children.isEmpty {
            self.gametrees.append(newGameTree)
            self.save()
            return true
        }
        else {
            return false
        }
    }
    
    func addExampleGameTree() {
        self.gametrees.append(GameTree.example())
        self.save()
    }
    
    func removeGameTree(at offsets: IndexSet) {
        self.gametrees.remove(atOffsets: offsets)
        self.save()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        appVersion = try container.decode(String.self, forKey: .appVersion)
        gametrees = try container.decode([GameTree].self, forKey: .gameTrees)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(gametrees, forKey: .gameTrees)
    }
    
    enum CodingKeys: String, CodingKey {
            case appVersion, gameTrees
    }
}
