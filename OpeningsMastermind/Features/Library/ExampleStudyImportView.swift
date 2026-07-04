//
//  ExampleStudyImportView.swift
//  OpeningsMastermind
//

import SwiftUI

/// "Examples" tab of `AddStudyView`: a fixed list of bundled example studies the
/// user can multi-select and import.
struct ExampleStudyImportView: View {
    @ObservedObject var database: DataBase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @Binding var isLoading: Bool

    @State private var selection = Set<ExamplePGN>()

    var body: some View {
        Group {
            List(selection: $selection) {
                ForEach(ExamplePGN.list, id: \.self) { listItem in
                    VStack(alignment: .leading) {
                        Text(listItem.name)
                        Text("created by \(listItem.creator)")
                            .font(Font.caption2)
                    }
                    .opacity(isImported(listItem) ? 0.5 : 1.0)
                    .padding(.vertical, 3)
                    .contextMenu {
                        Button{openURL(URL(string: listItem.url)!)} label: {
                            Label("Visit Study on Lichess.com", systemImage: "safari")
                        }
                    }
                    .if(isImported(listItem)) { view in
                        view._untagged()
                    }
                }
                .listRowBackground(colorScheme == .dark ? [28,28,30].getColor():Color.white)
            }
            .listStyle(.inset)
            .listRowSeparator(.hidden)

            Button(action: {
                addExamples()
            }) {
                Image(systemName: "plus.circle.fill")
                Text("Add selected Studies")
            }
            .foregroundColor(.green)
            .padding()
        }
    }

    /// Whether the example is already in the library (and so should be dimmed
    /// and unselectable). During screenshot seeding all five are pre-imported,
    /// so this is forced `false` to keep the Examples tab looking available.
    private func isImported(_ item: ExamplePGN) -> Bool {
        #if DEBUG
        if UITestSupport.showsExamplesAsAvailable { return false }
        #endif
        return database.gametrees.contains(where: { $0.name == item.name })
    }

    private func addExamples() {
        if selection.isEmpty { return }
        isLoading = true
        Task {
            for example in selection {
                if let pgnString = example.pgnString {
                    _ = await self.database.addNewGameTree(name: example.name, pgnString: pgnString, userColor: example.userColor)
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
        self.dismiss()
    }
}
