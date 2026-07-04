//
//  LichessStudyImportView.swift
//  OpeningsMastermind
//

import SwiftUI
import ChessKit

/// "Lichess" tab of `AddStudyView`: lists the signed-in user's Lichess studies
/// and imports the selected ones, each with a chosen board color.
struct LichessStudyImportView: View {
    @ObservedObject var database: DataBase
    @Environment(AppData.self) private var appData
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @Binding var isLoading: Bool

    @State private var vm = LichessStudyImportViewModel()

    var body: some View {
        @Bindable var vm = vm
        Group {
            List(selection: $vm.selection) {
                ForEach(vm.studyList, id: \.self) { study in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(study.name)
                            Text("last updated on " + dateStringFromTimestamp(study.updatedAt/1000))
                                .font(Font.caption)
                        }
                        .opacity(vm.databaseContainsStudy(study, in: database) ? 0.5 : 1.0)
                        .padding(.vertical, 3)
                        .contextMenu {
                            Button{openURL(URL(string: "https://lichess.org/study/\(study.id)")!)} label: {
                                Label("Visit Study on Lichess.com", systemImage: "safari")
                            }
                        }
                        Toggle("SelectColorPicker", isOn: vm.colorBinding(for: study.id))
                            .toggleStyle(WhitePieceToggleStyle())
                    }
                    .if(vm.databaseContainsStudy(study, in: database)) { view in
                        view._untagged()
                    }
                }
                .listRowBackground(colorScheme == .dark ? [28,28,30].getColor():Color.white)
            }
            .refreshable() {
                await vm.loadStudies(userName: appData.settings.lichessName, database: database)
            }
            .listStyle(.inset)

            Spacer()
            Button(action: {
                Task {
                    await addSelectedStudies()
                }
                dismiss()
            }) {
                Image(systemName: "plus.circle.fill")
                Text("Add selected Studies")
            }
            .foregroundColor(.green)
            .padding()
        }
        .task {
            await vm.loadStudies(userName: appData.settings.lichessName, database: database)
        }
    }

    private func addSelectedStudies() async {
        isLoading = true
        for study in vm.selection {
            do {
                let pgnString = try await LichessStudyService.pgn(forStudyID: study.id)
                var userColor = PieceColor.white
                if let colorIsWhite = vm.colorDict[study.id] {
                    userColor = colorIsWhite ? .white : .black
                }
                let _ = await database.addNewGameTree(name: study.name, pgnString: pgnString, userColor: userColor)
            } catch { }
        }
        await MainActor.run {
            isLoading = false
        }
    }

    private func dateStringFromTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
}
