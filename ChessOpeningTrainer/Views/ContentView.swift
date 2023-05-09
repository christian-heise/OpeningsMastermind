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
    @StateObject var vm = PractiseViewModel()
    
    var body: some View {
        TabView {
            
            PractiseView(database: database, settings: settings)
                .tabItem {
                    Label("Practise", systemImage: "checkerboard.rectangle")
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
            self.vm.gameTree = self.database.gametrees.first
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
