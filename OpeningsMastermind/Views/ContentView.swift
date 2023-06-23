//
//  ContentView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.04.23.
//

import SwiftUI
import ChessKit

struct ContentView: View {
    @StateObject var database: DataBase
    @StateObject var settings: Settings
    
    @StateObject var appControl: AppControlViewModel
    
    @StateObject var vm_ExploreView: ExploreViewModel
    
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        let database = DataBase()
        let settings = Settings()
        let vm_ExploreView = ExploreViewModel(database: database, settings: settings)
        self._database = StateObject(wrappedValue: database)
        self._settings = StateObject(wrappedValue: settings)
        self._vm_ExploreView = StateObject(wrappedValue: vm_ExploreView)
        self._appControl = StateObject(wrappedValue: AppControlViewModel(vm_ExploreView: vm_ExploreView))
    }
    
    var body: some View {
        let selectedTab = Binding {
            return self.appControl.selectedTab
        } set: { selection in
            self.appControl.selectedTab = selection
        }

        if database.isLoaded {
            TabView(selection: selectedTab) {
                ExploreView(database: database, settings: settings, vm: vm_ExploreView)
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
            .environmentObject(appControl)
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
                appControl.selectedTab = 2
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
