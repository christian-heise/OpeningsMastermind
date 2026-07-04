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
    @Environment(AppData.self) private var appData
    
    @State private var isShowingSwitchingView = false
    @State private var showingHelp = false
    @State private var didDismissSignInPrompt = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    
    init(database: DataBase, vm: ExploreViewModel) {
        self._vm = StateObject(wrappedValue: vm)
        self.database = database
    }
    
    /// iPhone in portrait. Here we render a fixed, non-collapsing large title
    /// (see header below) instead of the system large title, which collapses
    /// when the Lichess move list scrolls and—because it lives outside the
    /// `GeometryReader`—would otherwise resize the chessboard on collapse.
    private var isPhonePortrait: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isPhonePortrait {
                    Text("Explorer")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                }
                GeometryReader { geo in
                let layout = isLandscape(in: geo.size) ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
                layout {
                    HStack(spacing: 0) {
                        if appData.settings.engineOn {
                            EvalBarView(eval: vm.evaluation, mate: vm.mateInXMoves, userColor: vm.userColor)
                                .frame(width: 20)
                                .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        }
                        ChessboardView(vm: vm)
                            .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                    }
                    .if(!isLandscape(in: geo.size) && appData.settings.engineOn) { view in
                        view.frame(width: max(min(geo.size.width, max(geo.size.height - 50 - 40 - 85, 300)), 30), height: max(min(geo.size.width-20, max(geo.size.height - 50 - 40 - 85, 300)), 30))
                    }
                    .if(!isLandscape(in: geo.size) && !appData.settings.engineOn) { view in
                        view.frame(width: max(min(geo.size.width, max(geo.size.height - 50 - 40 - 85, 300)), 30), height: max(min(geo.size.width, max(geo.size.height - 50 - 40 - 85, 300)), 30))
                    }
                    .if(isLandscape(in: geo.size) && appData.settings.engineOn) { view in
                        view.frame(width: max(min(geo.size.height + 20, geo.size.width - 300), 30),
                                   height: max(min(geo.size.height, geo.size.width - 300), 30))
                    }
                    .if(isLandscape(in: geo.size) && !appData.settings.engineOn) { view in
                        view.frame(width: max(min(geo.size.height, geo.size.width - 300), 30),
                                   height: max(min(geo.size.height, geo.size.width - 300), 30))
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
                            Group {
                                if vm.showLichessExplorer {
                                    ScrollView {
                                        LichessExplorerView(vm: vm)
                                    }
                                    .scrollIndicators(.hidden)
                                } else if !didDismissSignInPrompt {
                                    Spacer()
                                    LichessSignInPrompt(
                                        signIn: { await vm.signInToLichess() },
                                        onDismiss: { didDismissSignInPrompt = true }
                                    )
                                    .padding(.vertical, 40)
                                }
                            }
                            .clipped()
                            .padding(.horizontal, 5)
                            .frame(minHeight: 40)
                            .if(isLandscape(in: geo.size)) { view in
                                view.padding(.top, 10)
                            }
                            if isLandscape(in: geo.size) {
                                MoveGridView(vm: vm)
                            } else {
                                MoveListView(vm: vm)
                                    .padding(.vertical, 7)
                                    .padding(.trailing, 7)
                                    .background(){
                                        (colorScheme == .dark ? [50,50,50] : [233,233,233]).getColor()
                                            .shadow(radius: 1)
                                    }
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
                                .accessibilityIdentifier("explorer.forwardButton")
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 47)
                        .padding(.bottom,5)
                    }

                }
                }
            }
            .sheet(isPresented: $showingHelp, content: {
                HelpExplorerView()
            })

            // On iPhone portrait the title is drawn as a fixed header above, so
            // suppress the (collapsing) system large title; everywhere else keep
            // the standard title behaviour.
            .navigationTitle(isPhonePortrait ? "" : "Explorer")
            .navigationBarTitleDisplayMode(isPhonePortrait || verticalSizeClass == .compact ? .inline : .large)
            .toolbar() {
                ToolbarItem() {
                    Button() {
                        isShowingSwitchingView = true
                    } label: {
                        HStack {
                            if let name = vm.gameTree?.name {
                                Text(name)
                            } else {
                                Text("Switch Study")
                            }
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding(.vertical, 1)
                        .padding(.trailing, 5)
                    }
                    .disabled(database.gametrees.isEmpty ? true : false)
                    .accessibilityIdentifier("explorer.switchStudyButton")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.userColor = vm.userColor.negotiated
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
                let gametrees = database.gametrees.sorted(by: {$0.dateLastPlayed > $1.dateLastPlayed})
                SwitchStudyView(selectGametree: { vm.reset(to: $0) }, gametrees: gametrees)
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

#Preview("No Lichess data") {
    let appData = AppData()
    let database = DataBase()
    ExploreView(database: database, vm: ExploreViewModel(database: database, appData: appData))
        .environment(appData)
}

#Preview("With Lichess moves") {
    let appData = AppData()
    let database = DataBase()
    ExploreView(
        database: database,
        vm: ExploreViewModel(
            database: database,
            appData: appData,
            previewLichessData: .example
        )
    )
    .environment(appData)
}
