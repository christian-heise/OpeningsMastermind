//
//  PractiseView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI
import ChessKit

struct PracticeView: View {
    @StateObject var vm = PracticeViewModel()
    
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings

    @State private var isShowingSwitchingView = false
    
    var text: String {
        if vm.gameState == 1 {
            return "This was the wrong move!"
        } else if vm.gameState == 2 {
            return "This was the last move in this Study"
        } else {
            return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    VStack {
                        Spacer()
                        ChessboardView(vm: vm, settings: settings)
                            .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                            .frame(maxHeight: geo.size.width)
                        ZStack {
                            if vm.gameState == 0 {
                                ScrollView {
                                    HStack {
                                        Text(vm.moveString)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .frame(width: geo.size.width, height: 100)
                            }
                            VStack {
                                Text(text)
                                    .frame(height: 20)
                                    .padding()
                                    .opacity(vm.gameState > 0 ? 1 : 0)
                                HStack {
                                    Button(action: {
                                        vm.revertMove()
                                    }) {
                                        Text("Revert Last Move")
                                            .padding()
                                            .foregroundColor(.white)
                                            .background([223,110,107].getColor())
                                            .cornerRadius(10)
                                    }
                                    .opacity(vm.gameState == 1 ? 1 : 0)
                                    .disabled(vm.gameState == 1 ? false : true)
                                    
                                    Button(action: {
                                        vm.resetGameTree()
                                    }) {
                                        Text("Restart Training")
                                            .padding()
                                            .foregroundColor(.white)
                                            .background([79,147,206].getColor())
                                            .cornerRadius(10)
                                    }
                                    .opacity(vm.gameState > 0 ? 1 : 0)
                                    .disabled(vm.gameState > 0 ? false : true)
                                    
                                    
                                }
                                .padding(10)
                            }
                        }
                    }
                    if database.gametrees.isEmpty {
                        VStack {
                            Spacer()
                            Text("You can add custom Studies or pick from 5 Example Studies in the Library.")
                                .foregroundColor(.black)
                                
                                .multilineTextAlignment(.leading)
                                .padding()
                                .background() {
                                    BoxArrowShape(cornerRadius: 5)
                                        .fill([242,242, 247].getColor())
                                        .shadow(radius: 2)
                                }
                                .padding(.vertical)
                                .frame(maxWidth: geo.size.width*3/5)
                                .offset(x: geo.size.width/8)
                        }
                    }
                }
                .navigationTitle(Text("Practice"))
                .toolbar() {
                    Button() {
                        isShowingSwitchingView = true
                        
                    } label: {
                        HStack {
                            Text(vm.gameTree?.name ?? "")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding(.vertical, 1)
                        .padding(.trailing, 5)
                    }
                    .background() {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                            .shadow(radius: 5)
                            .opacity(0.2)
                    }
                    .opacity(database.gametrees.isEmpty ? 0.0 : 1.0)
                    .disabled(database.gametrees.isEmpty ? true : false)
                }
                .sheet(isPresented: $isShowingSwitchingView) {
                    SwitchStudyView(vm: vm, database: database)
                }
                .onAppear() {
                    vm.onAppear(database: database)
                }
            }
        }
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
