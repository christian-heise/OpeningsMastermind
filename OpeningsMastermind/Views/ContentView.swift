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
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        if database.isLoaded {
            TabView(selection: $selectedTab) {
                ExploreView(database: database, settings: settings, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Explorer", systemImage: "book")
                    }
                    .tag(0)
//                PracticeView(database: database, settings: settings)
//                    .tabItem {
//                        Label("Practice", systemImage: "checkerboard.rectangle")
//                    }
//                    .tag(1)
                PracticeCenterView(database: database, settings: settings)
                    .tabItem {
                        Label("Center", systemImage: "list.bullet")
                    }
                    .tag(10)
                ListView(database: database, settings: settings)
                    .tabItem {
                        Label("Library", systemImage: "list.bullet")
                    }
                    .tag(2)
                SettingsView(settings: settings, database: database)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
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
            .onOpenURL { _ in
                selectedTab = 2
            }
        } else {
            LoadingView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
