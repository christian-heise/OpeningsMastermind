//
//  LoadingView.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 12.06.23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 50) {
            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                .resizable()
                .scaledToFit()
                .cornerRadius(100/6.4)
                .frame(width: 100)
            Text("Loading your database")
            ProgressView()
                .scaleEffect(1.5)
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
