//
//  ListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings
    
    @State private var showingAddSheet = false
    @State private var sortingElements: [SortingMethod] = [.name, .date, .progress, .manual]
    
    var sortedGameTrees: [GameTree] {
        if database.sortSelection == .name {
            if database.sortingDirectionIncreasing {
                return database.gametrees.sorted(by: {$0.name < $1.name})
            } else {
                return database.gametrees.sorted(by: {$0.name > $1.name})
            }
        } else if database.sortSelection == .date {
            if database.sortingDirectionIncreasing {
                return database.gametrees.sorted(by: {
                    if $0.date == $1.date {
                        return $0.name > $1.name
                    }
                    return $0.date > $1.date
                })
            } else {
                return database.gametrees.sorted(by: {
                    if $0.date == $1.date {
                        return $0.name < $1.name
                    }
                    return $0.date < $1.date
                })
            }
        } else if database.sortSelection == .progress {
            if database.sortingDirectionIncreasing {
                return database.gametrees.sorted(by: {$0.progress > $1.progress})
            } else {
                return database.gametrees.sorted(by: {$0.progress < $1.progress})
            }
        }
        return database.gametrees
    }
    
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
            }
        )
        
        NavigationStack {
            Group {
                List() {
                    ForEach(sortedGameTrees, id: \.self) { gameTree in
//                        NavigationLink(destination: PracticeView(database: database, settings: settings, gameTree: gameTree)) {
                            VStack(alignment: .leading) {
                                Text(gameTree.name)
                                    .fontWeight(.medium)
                                HStack {
                                    Text("Progress:")
                                    ProgressBarView(progress: gameTree.progress)
                                        .frame(height: 20)
                                }
                            }
//                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
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
        .onAppear() {
            if database.gametrees.isEmpty {
                showingAddSheet = true
            }
        }
    }
    

    
    func delete(at offsets: IndexSet) {
        let array = Array(offsets)
        for i in array {
            let deleteIndex = IndexSet(integer: database.gametrees.firstIndex(where: {$0 == sortedGameTrees[i]}) ?? .zero)
            database.removeGameTree(at: deleteIndex)
        }
        
        
    }
    
    func move(from source: IndexSet, to destination: Int) {
        database.gametrees.move(fromOffsets: source, toOffset: destination)
        database.sortSelection = .manual
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(database: DataBase(), settings: Settings())
    }
}
