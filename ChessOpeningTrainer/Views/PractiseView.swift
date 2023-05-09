//
//  PractiseView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI
import ChessKit

struct PractiseView: View {
    @EnvironmentObject var vm: PractiseViewModel
    
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings

    @State private var isShowingSwitchingView = false
    
    @State private var animationAmount: Double
    @State private var switchViewOffset: CGSize
    
    init(database: DataBase, settings: Settings) {
        self.database = database
        self.settings = settings
        
        self.animationAmount = 1.0
        self.switchViewOffset = .zero
    }
    var text: String {
        if vm.gameState == 1 {
            return "This was the wrong move!"
        } else if vm.gameState == 2 {
            return "This was the last move in this Study"
        } else {
            return ""
        }
    }
    
    var navigationTitle: String {
//        if isShowingSwitchingView {
//            return ""
//        }
        if database.gametrees.isEmpty {
            return "Practise"
        }
        if let name = vm.gameTree?.name {
            return name
        } else {
            return "Select Study first"
        }
        
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    HStack{
                        Spacer()
                        Button("Select Study") {
                            isShowingSwitchingView = true
                        }
                        .opacity(database.gametrees.isEmpty ? 0.0 : 1.0)
                        .disabled(database.gametrees.isEmpty ? true : false)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    HStack {
                        Text(navigationTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        Spacer()
                    }
                    Spacer()
                    ChessboardView(settings: settings)
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
                    //                    Text("Mistake Rate: \(String(format: "%0.2f",vm.gameTree?.currentNode?.mistakesRate ?? 0.0))")
                }
                if database.gametrees.isEmpty {
                    VStack {
                        Spacer()
                        Text("You can add custom Studies or pick from 5 Example Studies in the Library.")
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background() {
                                BoxArrowShape()
                                    .fill([242,242, 247].getColor())
                                    .shadow(radius: 2)
                            }
                            .padding(.vertical)
                            .frame(maxWidth: geo.size.width*3/5)
                    }
                }
            }
            .sheet(isPresented: $isShowingSwitchingView) {
                SwitchStudyView(database: database)
            }
        }
    }
}

struct PractiseView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
