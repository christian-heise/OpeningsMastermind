//
//  Settings.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import Foundation


class Settings: ObservableObject, Codable {
    @Published var boardColorRGB = BoardColorRGB()
    
    init() {
        self.load()
    }
    
    func resetColor() {
        self.boardColorRGB = BoardColorRGB()
    }
    
    func save() {
        let filename = getDocumentsDirectory().appendingPathComponent("settings.json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            try data.write(to: filename)
        } catch {
            print("Can not save settings")
        }
    }
    
    private func load() {
        let filename = getDocumentsDirectory().appendingPathComponent("settings.json")
        do {
            let data = try Data(contentsOf: filename)
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: data)
            self.boardColorRGB = settings.boardColorRGB
        } catch {
            print("Could not load database")
            self.save()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boardColorRGB = try container.decode(BoardColorRGB.self, forKey: .boardColorRGB)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boardColorRGB, forKey: .boardColorRGB)
    }
    
    enum CodingKeys: String, CodingKey {
            case boardColorRGB
    }
}

struct BoardColorRGB: Codable {
    var white = [255,255,255]
    var black = [171, 133, 102]
    
    // green: [93, 132, 101]
    // orange: [207, 133, 102]
}
