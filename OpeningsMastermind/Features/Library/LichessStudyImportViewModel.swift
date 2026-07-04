//
//  LichessStudyImportViewModel.swift
//  OpeningsMastermind
//

import SwiftUI

/// State and logic for the "Lichess" tab of `AddStudyView`: the fetched list of
/// the user's studies, the multi-selection, and the per-study white/black color
/// choice. Networking lives in `LichessStudyService`.
@Observable
final class LichessStudyImportViewModel {
    var studyList: [LichessStudyMetaData] = []
    var selection = Set<LichessStudyMetaData>()
    var colorDict: [String: Bool] = [:]

    /// Fetches the user's studies and re-sorts. Errors are logged and leave the
    /// current list untouched (matches the original pull-to-refresh behavior).
    func loadStudies(userName: String?, database: DataBase) async {
        guard let userName else { return }
        do {
            studyList = try await LichessStudyService.userStudies(for: userName)
            sortStudies(database: database)
        } catch {
            print(error)
        }
    }

    /// Studies already in the library sink to the bottom; otherwise newest-updated first.
    func sortStudies(database: DataBase) {
        studyList.sort { lhs, rhs in
            let lhsInDB = database.gametrees.contains { $0.name == lhs.name }
            let rhsInDB = database.gametrees.contains { $0.name == rhs.name }
            if lhsInDB != rhsInDB { return rhsInDB }
            return lhs.updatedAt > rhs.updatedAt
        }
        colorDict = Dictionary(uniqueKeysWithValues: studyList.map { ($0.id, true) })
    }

    func colorBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { self.colorDict[key] ?? true },
            set: { self.colorDict[key] = $0 }
        )
    }

    func databaseContainsStudy(_ study: LichessStudyMetaData, in database: DataBase) -> Bool {
        database.gametrees.contains { $0.name == study.name }
    }
}
