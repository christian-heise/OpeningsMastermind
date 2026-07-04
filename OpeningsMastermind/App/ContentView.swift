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
    @State var appData: AppData

    @StateObject var appControl: AppControlViewModel

    @StateObject var vm_ExploreView: ExploreViewModel

    @Environment(\.scenePhase) var scenePhase

    /// Drives the one-time "What's New" update splash. Set in `onAppear` when the
    /// last-seen version differs from the running app's version.
    @State private var showWhatsNew = false

    init() {
        #if DEBUG
        // Must run before `AppData`/`LichessAuthService` are constructed so an
        // injected Lichess token is in the keychain when the service reads it.
        UITestSupport.prepareIfNeeded()
        // Same ordering requirement for a manual Debug sign-in via DEBUG_LICHESS_TOKEN.
        UITestSupport.injectDebugLichessTokenIfNeeded()
        #endif

        let database = DataBase()
        // `AppData` is the source of truth + sole persister for settings.
        let appData = AppData()
        #if DEBUG
        UITestSupport.applySettings(to: appData)
        #endif
        let vm_ExploreView = ExploreViewModel(database: database, appData: appData)
        self._database = StateObject(wrappedValue: database)
        self._appData = State(initialValue: appData)
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
                ExploreView(database: database, vm: vm_ExploreView)
                    .tabItem {
                        Label("Explorer", systemImage: "book")
                            .accessibilityIdentifier("tab.explorer")
                    }
                    .tag(0)
//                PracticeView(database: database, settings: settings)
//                    .tabItem {
//                        Label("Practice", systemImage: "checkerboard.rectangle")
//                    }
//                    .tag(1)
                PracticeCenterView(database: database, appData: appData)
                    .tabItem {
                        Label("Practice", systemImage: "checkerboard.rectangle")
                            .accessibilityIdentifier("tab.practice")
                    }
                    .tag(10)
                ListView(database: database)
                    .tabItem {
                        Label("Library", systemImage: "list.bullet")
                            .accessibilityIdentifier("tab.library")
                    }
                    .tag(2)
                SettingsView(appData: appData)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                            .accessibilityIdentifier("tab.settings")
                    }
                    .tag(3)
            }
            .environmentObject(appControl)
            .environment(appData)
            .environment(\.locale, appData.settings.language.locale ?? Locale.autoupdatingCurrent)
            #if DEBUG
            .preferredColorScheme(UITestSupport.preferredColorScheme)
            #endif
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    database.save()
                    appData.save()
                }
            }
            .onAppear() {
                Task {
                    await appData.updateAllAccountDetails()
                }
                if appData.settings.lastSeenWhatsNewVersion != WhatsNewView.appVersion {
                    showWhatsNew = true
                }
                #if DEBUG
                UITestSupport.seed(into: database)
                #endif
            }
            .sheet(isPresented: $showWhatsNew, onDismiss: {
                appData.settings.lastSeenWhatsNewVersion = WhatsNewView.appVersion
                appData.save()
            }) {
                WhatsNewView(appData: appData)
            }
            .onOpenURL { _ in
                appControl.selectedTab = 2
            }
        } else {
            LoadingView()
        }
    }
}

#Preview {
    ContentView()
}
