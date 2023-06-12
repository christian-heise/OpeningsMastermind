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
    
    @Binding var selectedTab: Int
    
    @State private var isShowingSwitchingView = false
    @State private var showingHelp = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    
    init(database: DataBase, settings: Settings, selectedTab: Binding<Int>) {
        self._vm = StateObject(wrappedValue: ExploreViewModel(database: database, settings: settings))
        self.database = database
        self.settings = settings
        
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let layout = isLandscape(in: geo.size) ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
                layout {
                    HStack(spacing: 0) {
                        if settings.engineOn {
                            EvalBarView(eval: vm.evaluation, mate: vm.mateInXMoves, userColor: vm.userColor)
                                .frame(width: 20)
                                .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        }
                        ChessboardView(vm: vm, settings: settings)
                            .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                    }
                    .if(!isLandscape(in: geo.size)) { view in
                        view.frame(height: max(min(geo.size.width-20, max(geo.size.height - 50 - 40 - 85, 300)), 30))
                    }
                    .if(isLandscape(in: geo.size)) { view in
                        view.frame(width: max(min(geo.size.height+20, geo.size.width - 300), 30))
                    }
                        
                    VStack {
                        if vm.showingComment {
                            ScrollView(showsIndicators: false) {
                                Text(vm.comment)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                            }
                            .clipped()
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
                                LichessExplorerView(vm: vm)
                            }
                            .scrollIndicators(.hidden)
                            .clipped()
                            .padding(.horizontal, 5)
                            .frame(minHeight: 40)
                            .if(isLandscape(in: geo.size)) { view in
                                view.padding(.top, 10)
                            }
                            
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
                            }
                            .disabled(vm.comment == "")
                            .padding(.horizontal)
                            
                            Spacer()
                            HStack(spacing: 15) {
                                Button {
                                    print(geo.size.height)
                                    vm.reverseOneMove()
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
                                }
                                .disabled(vm.currentExploreNode.parent == nil)
                                Button {
                                    vm.forwardOneMove()
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
                                }
                                .disabled(vm.currentExploreNode.children.isEmpty && vm.currentExploreNode.gameNode?.children.isEmpty ?? true)
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 47)
                        .padding(.bottom,5)
                    }

                }
                .if(verticalSizeClass == .compact) { view in
                    view.navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showingHelp, content: {
                HelpExplorerView()
            })
            
            .navigationTitle("Explorer")
            .toolbar() {
                ToolbarItem() {
                    Button() {
                        isShowingSwitchingView = true
                    } label: {
                        HStack {
                            Text(vm.gameTree?.name ?? "Switch Study")
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
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.userColor = vm.userColor == .white ? .black : .white
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
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
    func isLandscape(in size: CGSize) -> Bool {
        size.width > size.height
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(database: DataBase(), settings: Settings())
//            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
//        ContentView(database: DataBase(), settings: Settings())
//            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
//        ContentView(database: DataBase(), settings: Settings())
//            .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch) (4th generation)"))
    }
}
