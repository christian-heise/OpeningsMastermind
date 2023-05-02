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
    
    @State private var editMode = EditMode.active
    
    @State private var pgnString = ""
    @State private var nameString = ""
    @State private var selectedColor = "white"
    
    @State private var nameError = false
    @State private var pgnError = false
    
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
                            .background(RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? .black : .white))
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
                } else {
                    List(selection: $exampleSelection) {
                        ForEach(ExamplePGN.list, id: \.self) { listItem in
                            HStack {
                                Text(listItem.gameTree!.name)
                            }
                        }
                        .listRowBackground(colorScheme == .dark ? [28,28,30].getColor():Color.white)
                    }.listStyle(.inset)
                        
                    
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
//            .padding()
            .navigationTitle(Text("Add Study"))
            .environment(\.editMode, $editMode)
            .toolbar {
                Button("Dismiss") {
                    dismiss()
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
        let examplesArray = Array(self.exampleSelection).sorted(by: {$0.gameTree!.name < $1.gameTree!.name})
        for example in examplesArray {
            self.database.addNewGameTree(example.gameTree!)
        }
        dismiss()
    }
}

struct AddStudyView_Previews: PreviewProvider {
    static var previews: some View {
        AddStudyView(database: DataBase())
    }
}
