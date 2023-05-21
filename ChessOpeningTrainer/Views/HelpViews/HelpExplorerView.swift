//
//  HelpExplorerView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.05.23.
//

import SwiftUI

struct HelpExplorerView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationStack {
            TabView() {
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.7, y: 0.04), maskFrame: CGSize(width: 0.6, height: 0.08), text: "Select an opening study to see its moves. If the button is hidden, add a custom study or example studies first.")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.075, y: 0.04), maskFrame: CGSize(width: 0.15, height: 0.08), text: "Rotate the Board")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.5, y: 0.7), maskFrame: CGSize(width: 1, height: 0.13), text: "See what other players in your rating range played on Lichess in the current position. You also see how those games resulted.\n\nIf your Lichess Account is not connected, moves by players between 1500 and 2500 are shown.")
                HelpExplorerPageView(maskPosition: CGPoint(x: 0.09, y: 0.88), maskFrame: CGSize(width: 0.18, height: 0.08), text: "Tap to show comments from the selected opening study (if comment is available)")
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle("Explorer Help")
            .toolbar {
                Button(action:{
                    self.presentationMode.wrappedValue.dismiss()
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
