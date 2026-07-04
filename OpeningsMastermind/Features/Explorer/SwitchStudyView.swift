//
//  SwitchStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 08.05.23.
//

import SwiftUI

struct SwitchStudyView: View {
    let selectGametree: (GameTree) -> Void
    let gametrees: [GameTree]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(gametrees) { gametree in
                Button {
                    selectGametree(gametree)
                    self.dismiss()
                } label: {
                    HStack {
                        Text(gametree.name)
                            .font(.title3)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding(.vertical, 7)
                }
            }
            .listStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical)
            
            .navigationTitle("Select a study")
            .toolbar {
                ToolbarItem {
                    Button("Dismiss Switch Study View", systemImage: "xmark") {
                        self.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SwitchStudyView(selectGametree: {_ in }, gametrees: [GameTree.example()])
}
