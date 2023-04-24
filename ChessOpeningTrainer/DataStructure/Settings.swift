//
//  Settings.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import Foundation


class Settings: Codable {
    var boardColorWhiteRGB = [0, 0, 0]
    var boardColorBlackRGB = [161, 132, 98]
    
    init() {
        self.load()
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
    
    func load() {
        let filename = getDocumentsDirectory().appendingPathComponent("settings.json")
        do {
            let data = try Data(contentsOf: filename)
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: data)
            self.boardColorWhiteRGB = settings.boardColorWhiteRGB
            self.boardColorBlackRGB = settings.boardColorBlackRGB
        } catch {
            print("Could not load database")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
