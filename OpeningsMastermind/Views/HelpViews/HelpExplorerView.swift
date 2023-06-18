//
//  HelpExplorerView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.05.23.
//

import SwiftUI

struct HelpExplorerView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            TabView() {
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.76, y: 0.04), maskFrame: CGSize(width: 0.48, height: 0.08), text: "Select an opening study to see the included moves as arrows.\n\nAdd a lichess or custom study in the library first.")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.075, y: 0.04), maskFrame: CGSize(width: 0.15, height: 0.08), text: "Rotate the Board")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.5, y: 0.69), maskFrame: CGSize(width: 1, height: 0.165), text: "See what other players in your rating range played on Lichess in the current position. You also see how those games resulted (white wins / draw / black wins)\n\nIf your Lichess Account is not connected, moves by players between 1500 and 2500 are shown.")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.09, y: 0.88), maskFrame: CGSize(width: 0.18, height: 0.08), text: "Tap to show comments from the selected opening study (if comment is available)")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.04, y: 0.38), maskFrame: CGSize(width: 0.08, height: 0.5), text: "Current Engine Evaluation\nby Sockfish 15")
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle("Explorer Help")
            .toolbar {
                Button(action:{
                    self.dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

struct HelpExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        HelpExplorerView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
        
        HelpExplorerView()
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
    }
}
