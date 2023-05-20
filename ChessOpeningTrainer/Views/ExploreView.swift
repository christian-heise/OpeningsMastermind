//
//  ExploreView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import SwiftUI

struct ExploreView: View {
    
    @StateObject var vm: ExploreViewModel
    
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings
    
    @State private var isShowingSwitchingView = false
    
    init(database: DataBase, settings: Settings) {
        self._vm = StateObject(wrappedValue: ExploreViewModel(database: database, settings: settings))
        self.database = database
        self.settings = settings
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    VStack {
                        ChessboardView(vm: vm, settings: settings)
                            .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                            .frame(height: geo.size.width)
                        Spacer()
                        if vm.showingComment {
                            ScrollView(showsIndicators: false) {
                                Text(vm.comment)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                            }
                            .background() {
                                ZStack{
                                    RoundedRectangle(cornerRadius: 10).fill(Color.gray).opacity(0.1)
                                    RoundedRectangle(cornerRadius: 10).stroke().opacity(0.5)
                                }
                                .padding(.horizontal, 5)
                            }
                            .frame(width: geo.size.width)
                            
                        } else {
                            ScrollView {
                                LichessExplorerView(openingData: vm.lichessResponse)
                            }
                            .padding(.horizontal, 5)
                            MoveListView(vm: vm)
                                .padding(.vertical, 7)
                                .padding(.trailing, 7)
                                .background(){
                                    Color.gray.opacity(0.1)
                                        .shadow(radius: 5)
                                }
                        }
                        HStack {
                            Button {
                                vm.showingComment.toggle()
                            } label: {
                                Image(systemName: "ellipsis.bubble")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                            }
                            .disabled(vm.comment == "")
                            .padding(.horizontal)
                            
                            Spacer()
                            HStack {
                                Button {
                                    vm.reverseMove()
                                } label: {
                                    Image(systemName: "arrow.backward")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(10)
                                        .background(){
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10).opacity(0.1)
                                            }
                                            .shadow(radius: 5)
                                        }
                                }
                                .disabled(vm.currentExploreNode.parent == nil)
                                Button {
                                    vm.forwardMove()
                                } label: {
                                    Image(systemName: "arrow.forward")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(10)
                                        .background(){
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10).opacity(0.1)
                                            }
                                            .shadow(radius: 5)
                                        }
                                }
                                .disabled(vm.currentExploreNode.children.isEmpty && vm.currentExploreNode.gameNode?.children.isEmpty ?? true)
                            }
                            .padding(.vertical, 0)
                            .padding(.horizontal)
                            .frame(width: geo.size.width / 10*4)
                        }
                        .padding(.bottom, 7)
                        
                    }
//                    if database.gametrees.isEmpty {
//                        VStack {
//                            Spacer()
//                            Text("You can add custom Studies or pick from 5 Example Studies in the Library.")
//                                .foregroundColor(.black)
//                            
//                                .multilineTextAlignment(.leading)
//                                .padding()
//                                .background() {
//                                    BoxArrowShape(cornerRadius: 5)
//                                        .fill([242,242, 247].getColor())
//                                        .shadow(radius: 2)
//                                }
//                                .padding(.vertical)
//                                .frame(maxWidth: geo.size.width*3/5)
//                                .offset(x: geo.size.width/8)
//                        }
//                    }
                }
            }
            .environmentObject(vm)
            .navigationTitle("Explorer")
            .toolbar() {
                ToolbarItem() {
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
                    .disabled(database.gametrees.isEmpty ? true : false)
                    .background() {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                            .shadow(radius: 5)
                            .opacity(0.2)
                    }
                    .opacity(database.gametrees.isEmpty ? 0.0 : 1.0)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.userColor = vm.userColor == .white ? .black : .white
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .sheet(isPresented: $isShowingSwitchingView) {
                SwitchStudyView(vm: vm, database: database)
            }
            .onAppear() {
                vm.onAppear()
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(database: DataBase(), settings: Settings())
//        ExploreView(database: DataBase(), settings: Settings())
    }
}
