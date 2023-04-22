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
    @Binding var showingPopover: Bool
    
    @State private var pgnString = ""
    @State private var nameString = ""
    @State private var selectedColor = "white"
    
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
            Form {
                TextField("Name of Study", text: $nameString)
                Picker("Your Piece Color", selection: $selectedColor) {
                    ForEach(colors, id:\.self) {
                        Text($0)
                    }
                }.pickerStyle(.segmented)
                Button("Get PGN from clipboard", action: {
                    let pasteboard = UIPasteboard.general
                    if let string = pasteboard.string {
                        self.pgnString = string
                    }
                })
//                Text("Enter PGN below:")
//                TextEditor(text: $pgnString)
//                    .frame(height: 200)
//                    .padding(10)
//                    .background(Color(.secondarySystemBackground))
//                    .cornerRadius(10)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(Color.gray, lineWidth: 1)
//                    )
//                    .padding()
                Section {
                    Button(action: {
                        database.addNewGameTree(name: nameString, pgnString: pgnString, userColor: .white)
                        self.showingPopover = false
                    }) {
                        Text("Enter")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    Button(action: {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = GameTree.examplePGN
                        nameString = "Smith Morra Gambit"
                    }) {
                        Text("Enter Example PGN")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle(Text("Add new Study"))
        }
    }
}

struct AddStudyView_Previews: PreviewProvider {
    static var previews: some View {
        AddStudyView(database: DataBase(),showingPopover: .constant(true))
    }
}
