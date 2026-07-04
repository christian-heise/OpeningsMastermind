//
//  AddStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import SwiftUI

/// Sheet for adding studies to the library. A thin shell hosting three
/// independent import tabs: custom PGN, the user's Lichess studies, and bundled
/// examples. Each tab lives in its own view; this view owns only the tab picker.
struct AddStudyView: View {
    @ObservedObject var database: DataBase
    @Environment(AppData.self) private var appData
    @Binding var isLoading: Bool
    @Binding private var pgnString: String

    @Environment(\.dismiss) private var dismiss

    @State private var editMode = EditMode.active
    @State private var importSelection = 0

    init(database: DataBase, isLoading: Binding<Bool>, pgnString: Binding<String>) {
        self.database = database
        self._isLoading = isLoading
        self._pgnString = pgnString
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch importSelection {
                case 0:
                    CustomPGNImportView(database: database, pgnString: $pgnString)
                case 1:
                    LichessStudyImportView(database: database, isLoading: $isLoading)
                default:
                    ExampleStudyImportView(database: database, isLoading: $isLoading)
                }

                Picker("Import Selector", selection: $importSelection) {
                    Text("Custom PGN").tag(0)
                        .accessibilityIdentifier("addStudy.tab.custom")
                    if appData.settings.playerRating != nil {
                        Text("Lichess").tag(1)
                            .accessibilityIdentifier("addStudy.tab.lichess")
                    }
                    Text("Examples").tag(2)
                        .accessibilityIdentifier("addStudy.tab.examples")
                }.pickerStyle(.segmented)
                .accessibilityIdentifier("addStudy.importPicker")
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationTitle(Text("Add Study"))
            .environment(\.editMode, $editMode)
            .toolbar {
                Button(action:{
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }
                .accessibilityIdentifier("addStudy.closeButton")
            }
        }
    }
}

struct AddStudyView_Previews: PreviewProvider {
    static var previews: some View {
        AddStudyView(database: DataBase(), isLoading: .constant(false), pgnString: .constant(""))
            .environment(AppData())
    }
}
