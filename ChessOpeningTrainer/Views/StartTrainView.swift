//
//  StartTrainView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import SwiftUI

struct StartTrainView: View {
    @ObservedObject var database: DataBase
    let settings: Settings
//    @StateObject var settings = Settings()
    
    @State private var showingAddSheet = false
//    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(database.gametrees) { gameTree in
                        NavigationLink(destination: TrainView(gameTree: gameTree, settings: settings)) {
                            Text(gameTree.name)
                        }
                    }
                    .onDelete(perform: delete)
                }
//                Button("Add Example GameTree", action: {
//                    self.database.addExampleGameTree()
//                })
            }
            .navigationTitle(Text("Opening Studies"))
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: {showingSettingsSheet = true}) {
//                        Image(systemName: "gear")
//                    }
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {showingAddSheet = true}) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddStudyView(database: database)
            }
//            .sheet(isPresented: $showingSettingsSheet) {
//                SettingsView(settings: settings)
//            }
        }
//        .toolbar(.visible, for: .tabBar)
    }
    
    func delete(at offsets: IndexSet) {
        database.removeGameTree(at: offsets)
    }
}

struct StartTrainView_Previews: PreviewProvider {
    static var previews: some View {
        StartTrainView(database: DataBase(), settings: Settings())
    }
}
