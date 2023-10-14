//
//  SelectStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.05.23.
//

import SwiftUI
import ChessKit

struct SelectStudyView: View {
    let gametrees: [GameTree]
    @ObservedObject var vm: PracticeViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var editMode = EditMode.active
    
    var body: some View {
        NavigationStack {
            VStack {
                List(selection: $vm.selectedGameTrees) {
                    ForEach(gametrees.filter({$0.userColor == vm.userColor}), id: \.self) { gametree in
                        /*@START_MENU_TOKEN@*/Text(gametree.name)/*@END_MENU_TOKEN@*/
                    }
                    .listRowBackground(colorScheme == .dark ? [28,28,30].getColor():Color.white)
                }
                Picker("User Color",selection: $vm.userColor) {
                    Text("white")
                        .tag(PieceColor.white)
                    Text("black")
                        .tag(PieceColor.black)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: vm.userColor) { color in
                    vm.selectedGameTrees = Set()
                }
            }
            .listStyle(.inset)
            .environment(\.editMode, $editMode)
            .navigationTitle("Select Studies to practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .onDisappear() {
                vm.currentNodes = vm.selectedGameTrees.map({$0.rootNode})
                vm.saveUserDefaults()
                vm.reset()
            }
        }
    }
}

struct SelectStudyView_Previews: PreviewProvider {
    static var previews: some View {
        SelectStudyView(gametrees: [GameTree.example(),GameTree.example()], vm: PracticeViewModel(database: DataBase(), settings: Settings()))
    }
}
