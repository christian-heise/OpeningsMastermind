//
//  SettingsView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 24.04.23.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            Form {
                Section() {
//                    Text("something")
                } footer: {
                    Text("Created by Christian Gleißner")
                }
            }
            .navigationTitle(Text("Settings"))
            .toolbar {
                Button("Dismiss") {
                    dismiss()
                }
            }
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
