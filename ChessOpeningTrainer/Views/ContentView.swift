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
    
    var body: some View {
        TabView {
            ExploreView(database: database, settings: settings)
                .tabItem {
                    Label("Explorer", systemImage: "book")
                }
            PracticeView(database: database, settings: settings, gameTree: GameTree.example())
                .tabItem {
                    Label("Practice", systemImage: "checkerboard.rectangle")
                }
            ListView(database: database, settings: settings)
                .tabItem {
                    Label("Library", systemImage: "list.bullet")
                }
            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                database.save()
                settings.save()
            }
        }
        .onAppear() {
            Task {
                await settings.updateAllAccountDetails()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
