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
                Text("Christian Gleißner\nFriedrichstr. 36\n95643 Tirschenreuth\nGermany")
                    .lineLimit(nil)
                    .padding()
                VStack(alignment: .leading) {
                    Text("Contact Information:")
                        .fontWeight(.bold)
                    Text("Email:  info@appsbychristian.com\nPhone: +49 9631 8692883\nMobile: +49 1579 2613741")
                        .lineLimit(nil)
                }
                .padding()
            }
        }
            .navigationTitle("Impressum")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ImpressumView_Previews: PreviewProvider {
    static var previews: some View {
        ImpressumView()
    }
}
