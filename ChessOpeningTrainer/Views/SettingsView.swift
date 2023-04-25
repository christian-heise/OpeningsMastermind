//
//  SettingsView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import SwiftUI

struct SettingsView: View {
//    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: Settings
    
    @State private var colorWhite: Color
    @State private var colorBlack: Color
    
    init(settings: Settings) {
        self.settings = settings
        self._colorWhite = State(initialValue: settings.boardColorRGB.white.getColor())
        self._colorBlack = State(initialValue: settings.boardColorRGB.black.getColor())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    ColorPicker("White board squares", selection: $colorWhite, supportsOpacity: false)
                    ColorPicker("Black board squares", selection: $colorBlack, supportsOpacity: false)
                    Button("Reset Colors") {
                        self.settings.resetColor()
                        self.colorWhite = settings.boardColorRGB.white.getColor()
                        self.colorBlack = settings.boardColorRGB.black.getColor()
                    }
                } header: {
                    Text("General")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
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
                    NavigationLink(destination: {ImpressumPrivacyView()}) {
                        Text("Legal Notice & Impressum")
                    }
                    NavigationLink(destination: {AcknowledgementsView()}){
                        Text("Acknoledgements")
                    }

                } header: {
                    Text("About")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                footer: {
                    Text("Created by Christian Gleißner")
                }
                Section() {
                    
                } header: {
                    Text("Contact")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
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
