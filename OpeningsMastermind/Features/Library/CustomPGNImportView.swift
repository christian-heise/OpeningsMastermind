//
//  CustomPGNImportView.swift
//  OpeningsMastermind
//

import SwiftUI
import ChessKit

/// "Custom PGN" tab of `AddStudyView`: name + color + a free-form PGN editor,
/// with clipboard paste and Lichess-URL import helpers. Owns `addStudy()`.
struct CustomPGNImportView: View {
    @ObservedObject var database: DataBase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding var pgnString: String

    @State private var nameString = ""
    @State private var selectedPieceColor: PieceColor = .white
    @State private var lichessURL = ""
    @State private var importProblemText = ""

    @State private var nameError = false
    @State private var pgnError = false
    @State private var duplicateError = false

    @State private var showingPGNHelp = false
    @State private var showingLichessAlert = false
    @State private var showingImportProblem = false

    var body: some View {
        Group {
            TextField("Name of Study", text: $nameString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(nameError ? Color.red : Color.gray, lineWidth: nameError ? 1 : 0.5)
                )
                .onSubmit {
                    addStudy()
                }
                .onTapGesture {
                    nameError = false
                }
                .padding(.horizontal)
                .onChange(of: nameString) {
                    nameError = false
                }

            VStack(alignment: .leading) {
                Text("Select your color:")
                    .font(.headline)

                Picker("Your Piece Color", selection: $selectedPieceColor) {
                    ForEach(PieceColor.allCases, id:\.self) {
                        Text($0.name)
                    }
                }.pickerStyle(.segmented)
            }
            .padding(.top)
            .padding(.horizontal)

            VStack() {
                HStack {
                    Text("Enter the PGN of your study:")
                        .font(.headline)
                    Button("Show PGN Help", systemImage: "questionmark.circle") {
                        self.showingPGNHelp = true
                    }.labelStyle(.iconOnly)
                    .popover(isPresented: $showingPGNHelp, attachmentAnchor: .point(.center), arrowEdge: .trailing, content: {
                        Text("Paste a custom PGN, or use the button below to import a lichess study with its URL. You also have the option to choose from 5 example studies")
                            .padding()
                            .frame(width: 300)
                            .truePopover()
                    })
                    Spacer()
                    Button(action: {
                        self.pgnString = ""
                    }) {
                        Image(systemName: "xmark.circle")
                    }
                }


                TextEditor(text: $pgnString)
                    .frame(minHeight: 40)
                    .padding(4)
                    .onSubmit {
                        addStudy()
                    }
                    .onTapGesture {
                        pgnError = false
                    }
                    .autocorrectionDisabled(true)
                    .keyboardType(.asciiCapable)
                    .scrollContentBackground(.hidden)
                    .background(ZStack(alignment: .topLeading){
                        RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? .black : .white)
                        if pgnString.isEmpty {
                            Text("Enter PGN here")
                                .foregroundColor(.gray)
                                .opacity(0.7)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 11)
                                .zIndex(10)
                        }
                    }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(pgnError ? Color.red : Color.gray, lineWidth: pgnError ? 1 : 0.5))
            }
            .padding(.top)
            .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    if let clipboardString = UIPasteboard.general.string {
                        pgnString = clipboardString
                        pgnError = false
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste Clipboard")
                }

                Button() {
                    showingLichessAlert = true
                } label: {
                    HStack{
                        Image(systemName: "square.and.arrow.down")
                        Text("Import PGN via Lichess URL")
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .alert(isPresented: $showingImportProblem) {
                Alert(title: Text(importProblemText))
            }

            Button(action: {
                addStudy()
            }) {
                Image(systemName: "plus.circle.fill")
                Text("Add Study")
            }
            .foregroundColor(.green)
            .padding(.bottom, 10)
            .alert(isPresented: $duplicateError) {
                Alert(title: Text("Duplicate"), message: Text("Library already contains study with this name"))
            }
        }
        .alert("Enter the Lichess Study URL", isPresented: $showingLichessAlert) {
            TextField("Lichess Study URL", text: $lichessURL)
            Button("Import") {
                Task {
                    do {
                        self.pgnString = try await LichessStudyService.pgn(fromStudyURL: lichessURL)
                    } catch let localError {
                        switch localError {
                        case LichessPGNError.urlInvalid:
                            importProblemText = "The provided URL is not valid."
                        case LichessPGNError.noLichessUrl:
                            importProblemText = "The provided URL is not a lichess.org URL."
                        case LichessPGNError.badResponse:
                            importProblemText = "A problem occured while downloading. Please try again later."
                        case LichessPGNError.createdUrlInvalid:
                            importProblemText = "A problem occured while downloading. Please try again later."
                        default:
                            break
                        }
                        showingImportProblem = true
                        lichessURL = ""
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Paste in the exact lichess.org url of the study you want to import.")
        }
        #if DEBUG
        .onAppear {
            if let name = UITestSupport.prefilledStudyName, nameString.isEmpty {
                nameString = name
            }
        }
        #endif
    }

    private func addStudy() {
        if pgnString.isEmpty && nameString.isEmpty {
            nameError = true
            pgnError = true
        } else if nameString.isEmpty {
            nameError = true
        } else if pgnString.isEmpty {
            pgnError = true
        } else if database.gametrees.contains(where: {$0.name == nameString}) {
            duplicateError = true
            nameError = true
        } else {
            Task {
                let result = await database.addNewGameTree(name: nameString, pgnString: pgnString, userColor: selectedPieceColor)
                await MainActor.run {
                    if result {
                        // Imported, but some games/moves may have been skipped.
                        if let message = database.lastImportMessage {
                            importProblemText = "The study was imported, but some lines were skipped:\n\n\(message)"
                            showingImportProblem = true
                        } else {
                            self.dismiss()
                        }
                    } else {
                        pgnError = true
                        if let message = database.lastImportMessage {
                            importProblemText = message
                            showingImportProblem = true
                        }
                    }
                }
            }
        }
    }
}
