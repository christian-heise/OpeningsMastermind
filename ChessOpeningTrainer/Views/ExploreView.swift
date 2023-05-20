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
    @State private var showingHelp = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(database: DataBase, settings: Settings) {
        self._vm = StateObject(wrappedValue: ExploreViewModel(database: database, settings: settings))
        self.database = database
        self.settings = settings
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack {
                    ChessboardView(vm: vm, settings: settings)
                        .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        .frame(height: geo.size.width)
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
                        .frame(minHeight: 40)
                        
                        MoveListView(vm: vm)
                            .padding(.vertical, 7)
                            .padding(.trailing, 7)
                            .background(){
                                (colorScheme == .dark ? [50,50,50] : [233,233,233]).getColor()
                                    .shadow(radius: 1)
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
                                            RoundedRectangle(cornerRadius: 10).opacity(0.4)
                                        }
                                        .shadow(radius: 5)
                                    }
                                    .frame(height: 40)
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
                                            RoundedRectangle(cornerRadius: 10).opacity(0.4)
                                        }
                                        .shadow(radius: 5)
                                    }
                                    .frame(height: 40)
                            }
                            .disabled(vm.currentExploreNode.children.isEmpty && vm.currentExploreNode.gameNode?.children.isEmpty ?? true)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .sheet(isPresented: $showingHelp, content: {
                HelpExplorerView()
            })
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
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
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
    }
}
