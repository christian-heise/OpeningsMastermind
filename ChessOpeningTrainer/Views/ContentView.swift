//
//  ContentView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.04.23.
//

import SwiftUI
import ChessKit

struct ContentView: View {
    @StateObject var database = DataBase()
    @StateObject var settings = Settings()
    
    @Environment(\.scenePhase) var scenePhase
    
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
//            StartTrainView(database: database, settings: settings)
//                .tabItem{
//                    Label("Practise Old", systemImage: "checkerboard.rectangle")
//                }
        }
        .onChange(of: scenePhase) { phase in
                if phase == .background {
                    database.save()
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
