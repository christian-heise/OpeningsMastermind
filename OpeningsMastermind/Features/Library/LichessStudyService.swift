//
//  LichessStudyService.swift
//  OpeningsMastermind
//

import Foundation

enum LichessPGNError: String, Error {
    case urlInvalid, noLichessUrl, badResponse, createdUrlInvalid, decodingError, noUserName
}

/// Metadata for a Lichess study, as returned by the `study/by/{user}` endpoint.
struct LichessStudyMetaData: Codable, Hashable {
    let id: String
    let name: String
    let createdAt: Int
    let updatedAt: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Fetches PGN data for a Lichess study, shared by `AddStudyView`'s manual-URL
/// import and `ListView`'s `onOpenURL` deep-link handler.
enum LichessStudyService {
    static func pgn(fromStudyURL urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw LichessPGNError.urlInvalid }
        let expectedHost = "lichess.org"
        let expectedPath = "/study/"

        guard url.host == expectedHost, url.path.starts(with: expectedPath) else { throw LichessPGNError.noLichessUrl }

        let id = url.lastPathComponent
        return try await pgn(forStudyID: id)
    }

    static func pgn(forStudyID id: String) async throws -> String {
        guard let apiURL = URL(string: "https://lichess.org/api/study/\(id).pgn") else { throw LichessPGNError.createdUrlInvalid }
        guard let (data, _) = try? await URLSession.shared.data(from: apiURL) else { throw LichessPGNError.badResponse }
        return try String(data: data, encoding: .utf8) ?? { throw LichessPGNError.badResponse }()
    }

    /// All studies authored by `user`, newest-updated first not guaranteed
    /// (caller sorts). Decodes the endpoint's NDJSON, one study per line.
    static func userStudies(for user: String) async throws -> [LichessStudyMetaData] {
        guard let url = URL(string: "https://lichess.org/api/study/by/\(user)") else { throw LichessPGNError.urlInvalid }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { throw LichessPGNError.badResponse }
        guard let ndjsonString = String(data: data, encoding: .utf8) else { throw LichessPGNError.decodingError }

        let decoder = JSONDecoder()
        var studies: [LichessStudyMetaData] = []
        for line in ndjsonString.components(separatedBy: .newlines) where !line.isEmpty {
            let study = try decoder.decode(LichessStudyMetaData.self, from: Data(line.utf8))
            studies.append(study)
        }
        return studies
    }
}
