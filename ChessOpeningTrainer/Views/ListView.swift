//
//  ListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var database: DataBase
    @EnvironmentObject var vm: PractiseViewModel
    @State private var showingAddSheet = false
    
    @State private var sortingElements: [SortingMethod] = [.name, .date, .progress, .manual]
    
    var body: some View {
        let sortSelectionBinding = Binding<SortingMethod>(
            get: {
                database.sortSelection
            },
            set: {
                if $0 == database.sortSelection && database.sortSelection != .manual {
                    database.sortingDirectionIncreasing.toggle()
                } else {
                    database.sortingDirectionIncreasing = true
                    database.sortSelection = $0
                }
                database.sortGameTree()
            }
        )
        
        NavigationStack {
            VStack {
                List() {
                    ForEach(database.gametrees) { gameTree in
                        VStack(alignment: .leading) {
                            Text(gameTree.name)
                                .fontWeight(.medium)
                            HStack {
                                Text("Progress:")
                                ProgressBarView(progress: gameTree.progress)
                                    .frame(height: 20)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }

                .navigationTitle(Text("Opening Studies"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                    ToolbarItem {
                        Menu {
                            Picker(selection: sortSelectionBinding, label: Text("Sorting options")) {
                                ForEach(sortingElements, id: \.self) { sorting in
                                    HStack {
                                        Text(sorting.rawValue)
                                        if database.sortSelection == sorting && sorting != .manual {
                                            Image(systemName: database.sortingDirectionIncreasing ? "chevron.down" : "chevron.up")
                                        }
                                    }
//                                    .tag(index)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem() {
                        Button(action: {showingAddSheet = true}) {
                            Image(systemName: "plus")
                        }
                        
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddStudyView(database: database)
                }
            }
        }
    }
    

    
    func delete(at offsets: IndexSet) {
        database.removeGameTree(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        database.gametrees.move(fromOffsets: source, toOffset: destination)
        database.sortSelection = .manual
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(database: DataBase())
    }
}
