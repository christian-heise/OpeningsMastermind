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
    
    @Published var sortSelection: SortingMethod = .manual
    @Published var sortingDirectionIncreasing: Bool = true
    
    init() {
        load()
    }
    
    init(gameTrees: [GameTree]) {
        self.gametrees = gameTrees
    }
    
    func save() {
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
            self.sortSelection = database.sortSelection
            self.sortingDirectionIncreasing = database.sortingDirectionIncreasing
            self.gametrees = database.gametrees
        } catch {
            print("Could not load database")
        }
    }
    
    func addNewGameTree(_ gameTree: GameTree) {
        self.gametrees.append(gameTree)
        self.save()
    }
    
    func addNewGameTree(name: String, pgnString: String, userColor: PieceColor) async -> Bool {
    
        let newGameTree = GameTree(name: name, pgnString: pgnString, userColor: userColor)
        
        if !newGameTree.rootNode.children.isEmpty {
            await MainActor.run {
                self.gametrees.append(newGameTree)
                self.save()
            }
            return true
        }
        else {
            return false
        }
    }
    
    func removeGameTree(at offsets: IndexSet) {
        self.gametrees.remove(atOffsets: offsets)
        self.save()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        self.sortSelection = try container.decodeIfPresent(SortingMethod.self, forKey: .sortSelection) ?? .manual
        self.sortingDirectionIncreasing = try container.decodeIfPresent(Bool.self, forKey: .sortingDirectionIncreasing) ?? true
        
        print(Double(self.appVersion) ?? 0.8)
        if Double(self.appVersion) ?? 0.7 < 0.7 {
            let oldGameTree = try container.decode([GameTreeOld].self, forKey: .gameTrees)
            print("Successfully loaded \(oldGameTree.count) old gametrees")
            self.gametrees = []
        } else {
            self.gametrees = try container.decode([GameTree].self, forKey: .gameTrees)
        }
        self.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(gametrees, forKey: .gameTrees)
        try container.encode(sortSelection, forKey: .sortSelection)
        try container.encode(sortingDirectionIncreasing, forKey: .sortingDirectionIncreasing)
    }
    
    enum CodingKeys: String, CodingKey {
            case appVersion, gameTrees, sortSelection, sortingDirectionIncreasing
    }
}
