//
//  ImpressumView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 26.04.23.
//

import SwiftUI

struct ImpressumView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("The following information (Impressum) is required under German law:")
                    .fontWeight(.bold)
                    .padding(.horizontal)
                Text("Christian Heise\nSteigerwaldstr. 25\n85049 Ingolstadt\nGermany")
                    .lineLimit(nil)
                    .padding()
                VStack(alignment: .leading) {
                    Text("Contact Information:")
                        .fontWeight(.bold)
                    Text("Email:  info@appsbychristian.de\nPhone: +49 841 90251152")
                        .lineLimit(nil)
                }
                .padding()
            }
        }
            .navigationTitle("Impressum")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ImpressumView()
    }
}
