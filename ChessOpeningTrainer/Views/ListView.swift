//
//  ListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var database: DataBase
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List() {
                    ForEach(database.gametrees) { gameTree in
                        //                        NavigationLink(destination: TrainView(gameTree: gameTree, database: database, settings: settings)) {
                        Text(gameTree.name)
                        //                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
                .navigationTitle(Text("Opening Studies"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(database: DataBase())
    }
}
