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
    @ObservedObject var settings: Settings
    @ObservedObject var database: DataBase
    
    @State private var colorWhite: Color
    @State private var colorBlack: Color
    
    @State private var showingLichessConnect = false
    @State private var showingChessComConnect = false
    
    @State private var userName = ""
    
    @Environment(\.requestReview) var requestReview
    
    init(settings: Settings, database: DataBase) {
        self.settings = settings
        self.database = database
        self._colorWhite = State(initialValue: settings.boardColorRGB.white.getColor())
        self._colorBlack = State(initialValue: settings.boardColorRGB.black.getColor())
    }
    
    var body: some View {
        let engineOn = Binding(
            get: { self.settings.engineOn },
            set: { self.settings.engineOn = $0 }
        )
        let engineType = Binding {
            return settings.engineType
        } set: { value in
            settings.engineType = value
        }

        NavigationStack {
            Form {
                HStack(alignment: .top){
                    Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                        .resizable()
                        .cornerRadius(60/6.4)
                        .frame(width:60, height: 60)
                    VStack(alignment: .leading) {
                        Text("Openings Mastermind")
                            .font(.title3)
                            .padding(.vertical, 1)
                        Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text("Copyright © 2023 Christian Gleißner")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                Section() {
                    ColorPicker("Light board squares", selection: $colorWhite, supportsOpacity: false)
                    ColorPicker("Dark board squares", selection: $colorBlack, supportsOpacity: false)
                    Button("Reset Colors") {
                        self.settings.resetColor()
                        self.colorWhite = settings.boardColorRGB.white.getColor()
                        self.colorBlack = settings.boardColorRGB.black.getColor()
                    }
                } header: {
                    Text("Board Style")
                        .fontWeight(.bold)
                }
                .onChange(of: self.colorWhite) { newValue in
                    self.settings.boardColorRGB.white = self.colorWhite.rgbValues
                    self.settings.save()
                }
                .onChange(of: self.colorBlack) { newValue in
                    self.settings.boardColorRGB.black = self.colorBlack.rgbValues
                    self.settings.save()
                }
                Section {
                    Picker("Lalala", selection: engineType) {
                        Text(EngineType.stockfish.name)
                            .tag(EngineType.stockfish)
                        Text(EngineType.lc0.name)
                            .tag(EngineType.lc0)
                    }
                    .pickerStyle(.segmented)
                    Toggle("Engine Evaluation", isOn: engineOn)
                } header: {
                    Text("Engine")
                        .fontWeight(.bold)
                }
                Section {
                    Group {
                        if let lichessName = settings.lichessName {
                            Button {
                                settings.resetAccount(for: .lichess)
                            } label: {
                                Label {
                                    Text("Disconnect \"" + lichessName + "\"")
                                        .foregroundColor(.red)
                                } icon: {
                                    Image("lichess_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 25)
                                }
                            }
//                            Button() {
//                                
//                            } label: {
//                                Label("Import public studies", systemImage: "square.and.arrow.down")
//                            }
                        } else {
                            Button {
                                showingLichessConnect = true
                            } label: {
                                Label {
                                    Text("Connect Lichess Account")
                                } icon: {
                                    Image("lichess_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 25)
                                }
                            }
                        }
                    }
                    .alert("Connect Lichess account", isPresented: $showingLichessConnect) {
                        TextField("Lichess username", text: $userName)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        Button("Connect") {
                            Task {
                                await settings.setAccountName(to: userName, for: .lichess)
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    }
//                    Button {
//                        showingChessComConnect = true
//                    } label: {
//                        HStack {
//                            Text("Connect Chess.com Account")
//                            Spacer()
//                            Image("chess.com_logo")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 30)
//                        }
//                    }
//                    .alert("Connect chess.com account", isPresented: $showingChessComConnect) {
//                        TextField("Chess.com username", text: $userName)
//                            .textInputAutocapitalization(.never)
//                            .disableAutocorrection(true)
//                        Button("Connect") {
//                            print("Chess.com connected")
//                        }
//                        Button("Cancel", role: .cancel) { }
//                    }

                } header: {
                    Text("Online Accounts")
                        .fontWeight(.bold)
                } footer: {
                    Text("Your Lichess information is used to filter moves in the Lichess opening explorer to better match your rating.")
                }
                Section() {
                    NavigationLink(destination: {ImpressumView()}) {
                        Text("Impressum")
                    }
                    NavigationLink(destination: {PrivacyView()}) {
                        Text("Privacy Policy")
                    }
                    NavigationLink(destination: {AcknowledgementsView()}){
                        Text("Acknowledgements")
                    }
                    Link("App on GitHub", destination: URL(string: "https://github.com/christiangleissner/OpeningsMastermind")!)
                } header: {
                    Text("About")
                        .fontWeight(.bold)
                }
                Section() {
                    Button("Rate my App") {
                        requestReview()
                    }
                    Link("Send me feedback", destination: URL(string: "mailto:feedback@appsbychristian.com")!)
                    Link("Visit my website", destination: URL(string: "https://appsbychristian.com/en/home-english/")!)
                } header: {
                    Text("Contact")
                        .fontWeight(.bold)
                }
            }
            .navigationTitle(Text("Settings"))
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: Settings(), database: DataBase())
    }
}
