//
//  SwitchStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 08.05.23.
//

import SwiftUI

struct SwitchStudyView: View {
    @ObservedObject var database: DataBase
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: PractiseViewModel
    
    var body: some View {
            VStack {
                HStack(alignment: .top) {
                    Text("Select a Study")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 7)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .padding(5)
                }
                
                List(database.gametrees.sorted(by: {$0.lastPlayed > $1.lastPlayed}), id: \.self) { gametree in
                    Button {
                        vm.resetGameTree(to: gametree)
                        dismiss()
                    } label: {
                        HStack {
                            Text(gametree.name)
                                .font(.title3)
                            Spacer()
                            Image(systemName: "arrowtriangle.right")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 7)
                    }
                }
                .listStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical)
    }
}

struct SwitchStudyView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
