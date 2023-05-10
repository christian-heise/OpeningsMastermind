//
//  ContentView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.04.23.
//

import SwiftUI
import ChessKit

struct ContentView: View {
    @StateObject var database: DataBase = DataBase()
    @StateObject var settings: Settings = Settings()
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var vm = PracticeViewModel()
    
    var body: some View {
        TabView {
            
            PracticeView(database: database, settings: settings)
                .tabItem {
                    Label("Practice", systemImage: "checkerboard.rectangle")
                }
            ListView(database: database)
                .tabItem {
                    Label("Library", systemImage: "list.bullet")
                }
            
            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(vm)
        .onChange(of: scenePhase) { phase in
                if phase == .background {
                    database.save()
                }
            }
        .onAppear() {
            self.vm.gameTree = self.database.gametrees.max(by: {$0.lastPlayed < $1.lastPlayed})
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
