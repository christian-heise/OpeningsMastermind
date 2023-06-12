//
//  SwitchStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 08.05.23.
//

import SwiftUI

struct SwitchStudyView: View {
    
    @ObservedObject var vm: ExploreViewModel
    @ObservedObject var database: DataBase
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
            VStack {
                HStack(alignment: .top) {
                    Text("Select a Study")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 7)
                    Spacer()
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .padding(5)
                }
                
                List(database.gametrees.sorted(by: {$0.dateLastPlayed > $1.dateLastPlayed}), id: \.self) { gametree in
                    Button {
                        vm.reset(to: gametree)
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack {
                            Text(gametree.name)
                                .font(.title3)
                            Spacer()
                            Image(systemName: "arrow.right")
//                                .foregroundColor(.green)
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
        SwitchStudyView(vm: ExploreViewModel(database: DataBase(), settings: Settings()), database: DataBase())
    }
}
