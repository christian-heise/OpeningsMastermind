//
//  SettingsView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
//    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: Settings
    
    @State private var colorWhite: Color
    @State private var colorBlack: Color
    
    @State private var showingLichessConnect = false
    @State private var showingChessComConnect = false
    
    @State private var userName = ""
    
    @Environment(\.requestReview) var requestReview
    
    init(settings: Settings) {
        self.settings = settings
        self._colorWhite = State(initialValue: settings.boardColorRGB.white.getColor())
        self._colorBlack = State(initialValue: settings.boardColorRGB.black.getColor())
    }
    
    var body: some View {
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
                    Text("General")
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
                    Group {
                        if let lichessName = settings.lichessName {
                            Button {
                                settings.resetAccount(for: .lichess)
                            } label: {
                                HStack {
                                    Text("Disconnect \"" + lichessName + "\"")
                                    Spacer()
                                    Image("lichess_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 30)
                                }
                            }
                            
                        } else {
                            Button {
                                showingLichessConnect = true
                            } label: {
                                HStack {
                                    Text("Connect Lichess Account")
                                    Spacer()
                                    Image("lichess_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 30)
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
                    Text("Connect")
                        .fontWeight(.bold)
                }
//            footer: {
//                    if settings.lichessName == nil && settings.chessComName == nil {
//                        Text("Currently connected to no account.")
//                    } else if settings.lichessName == nil {
//                        Text("Currently connected to chess.com account \"" + settings.chessComName! + "\"")
//                    } else if settings.chessComName == nil {
//                        Text("Currently connected to Lichess account \"" + settings.lichessName! + "\"")
//                    } else {
//                        Text("Currently connected to Lichess account \"" + settings.lichessName! + "\" and chess.com account \"" + settings.chessComName! + "\"")
//                    }
//                }
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

                } header: {
                    Text("About")
                        .fontWeight(.bold)
                }
                Section() {
                    Button("Rate my App") {
                        requestReview()
                    }
                    Text("[Send me feedback](mailto:feedback@appsbychristian.com)")
                    Text("[Visit my website](https://appsbychristian.com/en/home-english/)")
                } header: {
                    Text("Contact")
                        .fontWeight(.bold)
                }
            }
            .navigationTitle(Text("Settings"))
//            .toolbar {
//                Button("Dismiss") {
//                    dismiss()
//                    settings.save()
//                }
//            }
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: Settings())
    }
}
