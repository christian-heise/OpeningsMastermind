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
//                        .foregroundColor(.black)
                }
                .onChange(of: self.colorWhite) { newValue in
                    self.settings.boardColorRGB.white = self.colorWhite.rgbValues
                    self.settings.save()
                }
                .onChange(of: self.colorBlack) { newValue in
                    self.settings.boardColorRGB.black = self.colorBlack.rgbValues
                    self.settings.save()
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

                } header: {
                    Text("About")
                        .fontWeight(.bold)
//                        .foregroundColor(.black)
                }
//                footer: {
//                    Text("Copyright © 2023 Christian Gleißner")
//                }
                Section() {
                    Button("Rate my App") {
                        requestReview()
                    }
                    Link("Send me feedback", destination: URL(string: "mailto:feedback@appsbychristian.com")!)
                    Link("Visit my website", destination: URL(string: "https://appsbychristian.com/en/home-english/")!)
                } header: {
                    Text("Contact")
                        .fontWeight(.bold)
//                        .foregroundColor(.black)
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
