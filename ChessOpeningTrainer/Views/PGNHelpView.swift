//
//  PGNHelpView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import SwiftUI

struct PGNHelpView: View {
    var body: some View {
        VStack {
            Text("Copy a PGN text e.g. from a lichess study. Paste a single chapter or all chapters at once.")
        }
    }
}

struct PGNHelpView_Previews: PreviewProvider {
    static var previews: some View {
        PGNHelpView()
    }
}
