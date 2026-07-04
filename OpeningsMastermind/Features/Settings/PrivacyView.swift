//
//  PrivacyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 26.04.23.
//

import SwiftUI
import Textual

struct PrivacyView: View {
    @Environment(\.locale) private var locale

    private var markdown: String {
        let resourceName = locale.language.languageCode?.identifier == "de" ? "PrivacyPolicy-de" : "PrivacyPolicy-en"
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "md") else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    var body: some View {
        ScrollView {
            StructuredText(markdown: markdown)
                .padding(.horizontal)
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    NavigationStack {
        PrivacyView()
    }
}
