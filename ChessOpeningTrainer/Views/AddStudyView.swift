//
//  AddStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import SwiftUI
import ChessKit
import UniformTypeIdentifiers

struct AddStudyView: View {
    @ObservedObject var database: DataBase
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var pgnString = ""
    @State private var nameString = ""
    @State private var selectedColor = "white"
    
    @State private var nameError = false
    @State private var pgnError = false
    
    let colors = ["white", "black"]
    
    var selectedPieceColor: PieceColor {
        if self.selectedColor == "white" {
            return .white
        } else {
            return .black
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
//                    Text("Name of Study:")
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
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                VStack(alignment: .leading) {
                    Text("Select your color:")
                        .font(.headline)
                    
                    Picker("Your Piece Color", selection: $selectedColor) {
                        ForEach(colors, id:\.self) {
                            Text($0)
                        }
                    }.pickerStyle(.segmented)
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("Enter the PGN of your study:")
                        .font(.headline)
                    ZStack(alignment: .topLeading) {
                        if pgnString.isEmpty {
                            Text("Enter PGN here")
                                .foregroundColor(.gray)
                                .opacity(0.7)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .zIndex(10)
                        }
                        TextEditor(text: $pgnString)
                            .padding(4)
                            .zIndex(0)
                            .onSubmit {
                                addStudy()
                            }
                            .onTapGesture {
                                pgnError = false
                            }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(pgnError ? Color.red : Color.gray, lineWidth: pgnError ? 1 : 0.5))
                }
                .frame(minHeight: 50)
                    .padding()
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
                    .padding()
                    .foregroundColor(.green)
                }
                Button(action: {
                    pgnString = examplePGN
                    nameString = "Smith Morra Gambit"
                }) {
                    Text("Enter Example PGN")
                }
            }
            .navigationTitle(Text("Add Study"))
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
}

struct AddStudyView_Previews: PreviewProvider {
    static var previews: some View {
        AddStudyView(database: DataBase())
    }
}
