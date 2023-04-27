//
//  PrivacyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 26.04.23.
//

import SwiftUI
import MessageUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Personal data (usually referred to just as „data“ below) will only be processed by us to the extent necessary and for the purpose of providing a functional and user-friendly app, including its contents, and the services offered there.")
                    Text("Per Art. 4 No. 1 of Regulation (EU) 2016/679, i.e. the General Data Protection Regulation (hereinafter referred to as the „GDPR“), „processing“ refers to any operation or set of operations such as collection, recording, organization, structuring, storage, adaptation, alteration, retrieval, consultation, use, disclosure by transmission, dissemination, or otherwise making available, alignment, or combination, restriction, erasure, or destruction performed on personal data, whether by automated means or not.")
                    Text("Our privacy policy is structured as follows:")

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            Text("I.")
                                .frame(width: 20,alignment: .leading)
                            Text("Information about us as controllers of your data")
                        }
                        HStack(alignment: .top){
                            Text("II.")
                                .frame(width: 20,alignment: .leading)
                            Text("The rights of users and data subjects")
                        }
                        HStack(alignment: .top){
                            Text("III.")
                                .frame(width: 20,alignment: .leading)
                            Text("Information about the data processing")
                        }
                    }
                }
                Group {
                    Text("I. Information about us as controllers of your data")
                        .font(.headline)
                    Text("The party responsible for the app „Openings Mastermind“ (the „controller“) for purposes of data protection law is:")
                    Text("Christian, Gleißner\nFriedrichstr. 36\n95643, Tirschenreuth\nTelefon: [Telefonnummer]\nE-Mail: info@appsbychristian.com")
                    Text("The controller’s data protection officer is:")
                    Text("Christian, Gleißner\nTelefon: [Telefonnummer]\nE-Mail: info@appsbychristian.com")
                }
                Group {
                    Text("II. The rights of users and data subjects")
                        .font(.headline)
                    Text("With regard to the data processing to be described in more detail below, users and data subjects have the right")
                    BulletList(listItems: ["to confirmation of whether data concerning them is being processed, information about the data being processed, further information about the nature of the data processing, and copies of the data (cf. also Art. 15 GDPR);", "to correct or complete incorrect or incomplete data (cf. also Art. 16 GDPR);", "to the immediate deletion of data concerning them (cf. also Art. 17 DSGVO), or, alternatively, if further processing is necessary as stipulated in Art. 17 Para. 3 GDPR, to restrict said processing per Art. 18 GDPR;", "to receive copies of the data concerning them and/or provided by them and to have the same transmitted to other providers/controllers (cf. also Art. 20 GDPR);","to file complaints with the supervisory authority if they believe that data concerning them is being processed by the controller in breach of data protection provisions (see also Art. 77 GDPR)."])
                    Text("In addition, the controller is obliged to inform all recipients to whom it discloses data of any such corrections, deletions, or restrictions placed on processing the same per Art. 16, 17 Para. 1, 18 GDPR. However, this obligation does not apply if such notification is impossible or involves a disproportionate effort. Nevertheless, users have a right to information about these recipients.")
                    Text("Likewise, under Art. 21 GDPR, users and data subjects have the right to object to the controller’s future processing of their data pursuant to Art. 6 Para. 1 lit. f) GDPR. In particular, an objection to data processing for the purpose of direct advertising is permissible.")
                        .fontWeight(.bold)
                }
                Group {
                    Text("III. Information about the data processing")
                        .font(.headline)
                    Text("Your data processed when using our app will be deleted or blocked as soon as the purpose for its storage ceases to apply, provided the deletion of the same is not in breach of any statutory storage obligations or unless otherwise stipulated below.")
                }
                Group {
                    Text("Testflight")
                        .font(.title2)
                    Text("We use the TestFlight Service provided by Apple Inc. to test beta versions of our app. Participation in the beta program is voluntary. The purpose of the testing is to obtain feedback on the latest changes and to prevent bugs from being included in official releases. Apple collects the following data from beta testers and shares it with the developer:")
                    BulletList(listItems: ["Email Address (if user got invitation to TestFlight by email)","Name (entered by developer, if developer invited user to Testflight)","Invitation Type (whether user was invited via email or through a public link)","Installs (the number of times you have installed a beta build)","Sessions (the number of times you have used a beta build)","Crashes (the number of crashes per beta build)"])
                    Text("In addition, users have the option to voluntarily send feedback or crash reports to Apple, which is then shared with the developer. This data is stored for up to one year. The following data may be collected when sending feedback or a crash report:")
                    Text("App name, app version, installed app version, device, iOS Version, macOS Version, system language, carrier, time zone, device architecture, connection type, paired Apple Watches, screenshots, comments, app uptime, free disk space, battery level, screen resolution, crash logs")
                    Text("We take the privacy of our users seriously and do not sell or share any personal information with third parties. By participating in our beta program, you agree to the collection and use of your data as outlined in this privacy policy.")
                    Text("TestFlight, iOS, macOS, Apple Watch and Apple are trademarks of Apple Inc., registered in the U.S. and other countries and regions.")
                }
                Group{
                    Text("[Model Data Protection Statement](https://generator-datenschutzerkl%C3%A4rung.de/) of [Anwaltskanzlei Weiß & Partner](https://ratgeberrecht.eu/)")
                }
            }
            .padding(.horizontal)
            .navigationTitle("Privacy Policy")
        }
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}
