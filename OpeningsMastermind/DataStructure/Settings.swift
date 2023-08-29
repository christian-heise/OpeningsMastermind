//
//  Settings.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import Foundation
import ChessKitEngine

class Settings: ObservableObject, Codable {
    @Published var boardColorRGB = BoardColorRGB()
    
    @Published private (set) var lichessName: String?
    @Published private (set) var chessComName: String?
    
    @Published var engineOn: Bool = true
    
    var engineType: EngineType = .stockfish
    
    private (set) var playerRating: Int? = nil
    
    init() {
        self.load()
    }
    
    func resetColor() {
        self.boardColorRGB = BoardColorRGB()
    }
    
    func resetAccount(for platform: ChessPlatform) {
        switch platform {
        case .chessDotCom:
            self.chessComName = nil
        case .lichess:
            self.lichessName = nil
            self.playerRating = nil
        }
    }
    
    func setAccountName(to user: String, for platform: ChessPlatform) async {
        guard await userCheck(of: user, for: platform) else { return }
        
        await MainActor.run {
            switch platform {
            case .chessDotCom:
                self.chessComName = user
            case .lichess:
                self.lichessName = user
            }
            objectWillChange.send()
        }
        self.save()
        await updateAllAccountDetails()
    }
    
    func updateAllAccountDetails() async {
        if self.lichessName != nil {
            await updateAccountDetails(for: .lichess)
        }
        if self.chessComName != nil {
            await updateAccountDetails(for: .chessDotCom)
        }
    }
    
    func updateAccountDetails(for platform: ChessPlatform) async {
        switch platform {
        case .chessDotCom:
            print("Chess.com")
        case .lichess:
            let urlString = "https://lichess.org/api/user/\(lichessName!)"
            guard let url = URL(string: urlString) else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            
            guard let decodedData = try? JSONDecoder().decode(LichessUserData.self, from: data) else { return }
            
            self.playerRating = decodedData.perfs.blitz.rating
        }
    }
    
    func userCheck(of user: String, for platform: ChessPlatform) async -> Bool {
        switch platform {
        case .chessDotCom:
            return true
        case .lichess:
            let urlString = "https://lichess.org/api/users/status?ids=\(user)"
            guard let url = URL(string: urlString) else {
                print("bad url")
                return false }
            guard let (data, _) = try? await URLSession.shared.data(from: url) else {
                print("URL Session failed")
                return false
            }
            
            guard let decodedData = try? JSONDecoder().decode([LichessUserResponse].self, from: data) else {
                print("Decoding Failed")
                return false }
            
            
            return !(decodedData.first?.name.isEmpty ?? true)
        }
        
        struct LichessUserResponse: Codable {
            let name: String
            let id: String
        }
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
            self.playerRating = settings.playerRating
            self.lichessName = settings.lichessName
            self.chessComName = settings.chessComName
            self.engineOn = settings.engineOn
            self.engineType = settings.engineType
        } catch {
            print("Could not load settings")
            self.save()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boardColorRGB = try container.decode(BoardColorRGB.self, forKey: .boardColorRGB)
        
        self.playerRating = try container.decodeIfPresent(Int.self, forKey: .playerRating)
        self.lichessName = try container.decodeIfPresent(String.self, forKey: .lichessName)
        self.chessComName = try container.decodeIfPresent(String.self, forKey: .chessComName)
        self.engineOn = try container.decodeIfPresent(Bool.self, forKey: .engineOn) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boardColorRGB, forKey: .boardColorRGB)
        
        try container.encode(playerRating, forKey: .playerRating)
        try container.encode(lichessName, forKey: .lichessName)
        try container.encode(chessComName, forKey: .chessComName)
        try container.encode(engineOn, forKey: .engineOn)
    }
    
    enum CodingKeys: String, CodingKey {
            case boardColorRGB, playerRating, lichessName, chessComName, engineOn
    }
}

struct BoardColorRGB: Codable {
    var white = [255,255,255]
    var black = [171, 133, 102]
    
    // green: [93, 132, 101]
    // orange: [207, 133, 102]
}

enum ChessPlatform {
    case chessDotCom, lichess
}
