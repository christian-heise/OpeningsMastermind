//
//  SettingsView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import SwiftUI
import StoreKit
import ChessKitEngine

struct SettingsView: View {
    @State private var vm: SettingsViewModel
    @State private var showingLichessInfo = false

    @Environment(\.requestReview) var requestReview

    init(appData: AppData) {
        self._vm = State(initialValue: SettingsViewModel(appData: appData))
    }

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            Form {
                HStack(alignment: .top) {
                    Image("AppIconImage")
                        .resizable()
                        .cornerRadius(60 / 6.4)
                        .frame(width: 60, height: 60)
                    VStack(alignment: .leading) {
                        Text("Openings Mastermind")
                            .font(.title3)
                            .padding(.vertical, 1)
                        Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                        Text("Copyright © 2026 Christian Heise")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
                Section("General") {
                    Picker("Language", selection: $vm.language) {
                        Text("Automatic").tag(AppLanguage.auto)
                        Text("English").tag(AppLanguage.english)
                        Text("German").tag(AppLanguage.german)
                    }
                }
                Section("Board Customization") {
                    ColorPicker("Light board squares", selection: $vm.boardColorWhite, supportsOpacity: false)
                    ColorPicker("Dark board squares", selection: $vm.boardColorBlack, supportsOpacity: false)
                    Button("Reset Colors") {
                        vm.resetColor()
                    }
                }
                Section("Explorer") {
                    Toggle("Engine Evaluation", isOn: $vm.engineOn)
                }
                Section("Practice") {
                    Text("Computer Move delay: \(vm.moveDelay_ms, specifier: "%.0f")ms")
                    HStack {
                        Text("0ms")
                        Slider(value: $vm.moveDelay_ms, in: 0...1000)
                            .onTapGesture(count: 2) {
                                vm.resetMoveDelay()
                            }
                        Text("1000ms")
                    }
                }
                Section {
                    if vm.isSignedInToLichess {
                        Button {
                            vm.signOutOfLichess()
                        } label: {
                            Label {
                                Text("Sign out of \"\(vm.lichessName ?? "Lichess")\"")
                                    .foregroundStyle(.red)
                            } icon: {
                                Image("lichess_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25)
                            }
                        }
                    } else {
                        Button {
                            Task { await vm.signInToLichess() }
                        } label: {
                            Label {
                                Text("Sign in with Lichess")
                            } icon: {
                                Image("lichess_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25)
                            }
                        }
                        Button {
                            showingLichessInfo = true
                        } label: {
                            Label("Why sign in?", systemImage: "info.circle")
                        }
                    }
                } header: {
                    Text("Online Accounts")
                } footer: {
                    Text("Sign in with your Lichess account to use the opening explorer (Lichess now requires sign-in for it) and to import studies from your account. Your blitz rating is also used to filter explorer moves to better match your level.")
                }
                Section {
                    Toggle("Share Analytics", isOn: $vm.analyticsEnabled)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Help improve the app by sharing anonymous usage data and crash reports.")
                }
                Section("About") {
                    NavigationLink("Impressum") { ImpressumView() }
                    NavigationLink("Privacy Policy") { PrivacyView() }
                    NavigationLink("Acknowledgements") { AcknowledgementsView() }
                    Link("App on GitHub", destination: URL(string: "https://github.com/christian-heise/OpeningsMastermind")!)
                }
                Section("Contact") {
                    Button("Rate my App") {
                        requestReview()
                    }
                    Link("Send me feedback", destination: URL(string: "mailto:feedback@appsbychristian.de")!)
                    Link("Visit my website", destination: URL(string: "https://appsbychristian.de/")!)
                }
            }
            .navigationTitle("Settings")
            .headerProminence(.increased)
            .sheet(isPresented: $showingLichessInfo) {
                LichessAuthInfoView()
            }
        }
    }
}

#Preview {
    SettingsView(appData: AppData())
}
