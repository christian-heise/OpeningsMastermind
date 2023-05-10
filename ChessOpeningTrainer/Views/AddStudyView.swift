//
//  AddStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import Popovers
import SwiftUI
import ChessKit
import UniformTypeIdentifiers

struct AddStudyView: View {
    @ObservedObject var database: DataBase
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var editMode = EditMode.active
    
    @State private var pgnString = ""
    @State private var nameString = ""
    @State private var selectedColor = "white"
    
    @State private var nameError = false
    @State private var pgnError = false
    @State private var duplicateError = false
    
    @State private var showingPGNHelp = false
    
    @State private var examplePicker = 0
    
    @State private var exampleSelection = Set<ExamplePGN>()
    
    let colors = ["white", "black"]
    
    var selectedPieceColor: PieceColor {
        if self.selectedColor == "white" {
            return .white
        } else {
            return .black
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if examplePicker == 0 {
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
                        .onChange(of: nameString) { newValue in
                            nameError = false
                        }
                    
                    VStack(alignment: .leading) {
                        Text("Select your color:")
                            .font(.headline)
                        
                        Picker("Your Piece Color", selection: $selectedColor) {
                            ForEach(colors, id:\.self) {
                                Text($0)
                            }
                        }.pickerStyle(.segmented)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    
                    VStack() {
                        HStack {
                            Text("Enter the PGN of your study:")
                                .font(.headline)
                            Button(action: {
                                self.showingPGNHelp = true
                            }) {
                                Image(systemName: "questionmark.circle")
                            }
                            .popover(present: $showingPGNHelp, attributes: {
                                $0.position = .absolute(
                                    originAnchor: .top,
                                    popoverAnchor: .bottom
                                )
                                $0.rubberBandingMode = .none
                            }) {
                                Templates.Container(
                                    arrowSide: .bottom(.centered),
                                    backgroundColor: [173, 216, 230].getColor()
                                )
                                {
                                    PGNHelpView()
                                }
                                .frame(maxWidth: 200)
                            }
                            Spacer()
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
                    HStack {
                        Button(action: {
                            if let clipboardString = UIPasteboard.general.string {
                                pgnString = clipboardString
                                pgnError = false
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste Clipboard")
                        }
                        .padding()
                        
                        Button(action: {
                            addStudy()
                        }) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Study")
                        }
                        .foregroundColor(.green)
                        .padding()
                    }
                    .alert(isPresented: $duplicateError) {
                        Alert(title: Text("Duplicate"), message: Text("Library already contains study with this name"))
                    }
                } else {
                    List(selection: $exampleSelection) {
                        ForEach(ExamplePGN.list, id: \.self) { listItem in
                            VStack(alignment: .leading) {
                                Text(listItem.gameTree!.name)
                                Text("created by " + listItem.creator)
                                    .font(Font.caption2)
                            }
                            .opacity(database.gametrees.contains(listItem.gameTree!) ? 0.5 : 1.0)
                            .padding(.vertical, 3)
                            .contextMenu {
                                Button{openURL(URL(string: listItem.url)!)} label: {
                                    Label("Visit Study on Lichess.com", systemImage: "safari")
                                }
                            }
                            .if(database.gametrees.contains(listItem.gameTree!)) { view in
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
                Picker("awdawd", selection: $examplePicker) {
                    Text("Custom Study").tag(0)
                    Text("Example Studies").tag(1)
                }.pickerStyle(.segmented)
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
            }
        }
    }
    
    func addStudy() {
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
            if database.addNewGameTree(name: nameString, pgnString: pgnString, userColor: selectedPieceColor) {
                dismiss()
            } else {
                pgnError = true
            }
        }
    }
    
    func addExamples() {
        if exampleSelection.isEmpty { return }
        Task {
            for example in exampleSelection {
                self.database.addNewGameTree(GameTree(with: example.gameTree!))
            }
        }
        dismiss()
    }
}

struct AddStudyView_Previews: PreviewProvider {
    static var previews: some View {
        AddStudyView(database: DataBase())
    }
}
