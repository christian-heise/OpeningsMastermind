//
//  SwitchStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 08.05.23.
//

import SwiftUI

struct SwitchStudyView: View {
    @ObservedObject var database: DataBase
    @EnvironmentObject var vm: PractiseViewModel
    @Binding var isShowingSwitchingView: Bool
    @Binding var switchViewOffset: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill([242,242, 247].getColor())
                .shadow(radius: 2)
            VStack {
                HStack(alignment: .top) {
                    Text("Select a Study")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 7)
                    Spacer()
                    Button {
                        isShowingSwitchingView = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .padding(5)
                }
                
                List(database.gametrees, id: \.self) { gametree in
                    Button {
                        vm.resetGameTree(to: gametree)
                        isShowingSwitchingView = false
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
                    .listRowBackground(
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.white)
                                .padding(.vertical, 3)
                        }
                    )
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }
}

struct SwitchStudyView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
