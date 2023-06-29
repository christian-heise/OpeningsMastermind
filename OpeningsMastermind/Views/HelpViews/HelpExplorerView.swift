//
//  HelpExplorerView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.05.23.
//

import SwiftUI

struct HelpExplorerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    var body: some View {
        NavigationStack {
            TabView() {
                if verticalSizeClass == .compact {
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.85, y: 0.045), maskFrame: CGSize(width: 0.3, height: 0.1), text: "Select an opening study to see the included moves as arrows.\n\nAdd a lichess or custom study in the library first.", textYPos: 0.3, isLandscape: true)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.045, y: 0.04), maskFrame: CGSize(width: 0.08, height: 0.08), text: "Rotate the Board", textYPos: 0.1, textXPos: 0.35, isLandscape: true)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.73, y: 0.24), maskFrame: CGSize(width: 0.55, height: 0.3), text: "See what other players in your rating range played on Lichess in the current position, including, how those games resulted (white wins / draw / black wins)", textYPos: 0.6, isLandscape: true)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.515, y: 0.8), maskFrame: CGSize(width: 0.11, height: 0.2), text: "Tap to show comments from the selected opening study (if comment is available)", textYPos: 0.4, isLandscape: true)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.02, y: 0.47), maskFrame: CGSize(width: 0.04, height: 0.83), text: "Current Engine Evaluation\nby Sockfish 15", textYPos: 0.35, textXPos: 0.35, isLandscape: true)
                } else {
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.76, y: 0.04), maskFrame: CGSize(width: 0.48, height: 0.08), text: "Select an opening study to see the included moves as arrows.\n\nAdd a lichess or custom study in the library first.", textYPos: 0.28)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.075, y: 0.04), maskFrame: CGSize(width: 0.15, height: 0.08), text: "Rotate the Board", textYPos: 0.1, textXPos: 0.55)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.5, y: 0.69), maskFrame: CGSize(width: 1, height: 0.165), text: "See what other players in your rating range played on Lichess in the current position. You also see how those games resulted (white wins / draw / black wins)", textYPos: 0.38)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.10, y: 0.88), maskFrame: CGSize(width: 0.19, height: 0.08), text: "Tap to show comments from the selected opening study (if comment is available)", textYPos: 0.63)
                    HelpExplorerPageView(maskPosition: CGPoint(x: 0.025, y: 0.37), maskFrame: CGSize(width: 0.05, height: 0.51), text: "Current Engine Evaluation\nby Sockfish 15", textYPos: 0.35, textXPos: 0.55)
                }
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
