//
//  ImpressumPrivacyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import SwiftUI

struct ImpressumPrivacyView: View {
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
                VStack(alignment: .leading) {
                    Text("Online Dispute Resolution website of the EU Commission")
                        .fontWeight(.bold)
                    Text("In order for consumers and traders to resolve a dispute out-of-court, the European Commission developed the Online Dispute Resolution Website: www.ec.europa.eu/consumers/odr")
                }
                .padding()
                VStack(alignment: .leading) {
                    Text("Legal Disclaimer")
                        .fontWeight(.bold)
                    Text("The contents of these pages were prepared with utmost care. Nonetheless, we cannot assume liability for the timeless accuracy and completeness of the information.")
                }
                .padding()
                VStack(alignment: .leading) {
                    Text("Data protection")
                        .fontWeight(.bold)
                    Text("In general, when visiting the app „Chess Opening Trainer“, no personal data is saved. However, these data can be given on a voluntary basis. No data will be passed on to third parties without your consent. We point out that in regard to unsecured data transmission in the internet (e.g. via email), security cannot be guaranteed. Such data could possibIy be accessed by third parties.")
                }
                .padding()
                Text("English disclaimer by Language-Boutique.de")
                    .italic()
                    .padding()
            }
            .navigationTitle("Legal Notice")
        }
    }
}

struct ImpressumPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        ImpressumPrivacyView()
    }
}
