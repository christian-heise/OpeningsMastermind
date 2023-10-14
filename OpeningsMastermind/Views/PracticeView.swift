//
//  PractiseView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI
import ChessKit

struct PracticeView: View {
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings
    @ObservedObject var vm: PracticeViewModel
    
    @EnvironmentObject var appControl: AppControlViewModel
    
    @Environment(\.dismiss) var dismiss

    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingSelectView = false

    init(database: DataBase, settings: Settings, vm: PracticeViewModel) {
        self.vm = vm
        self.database = database
        self.settings = settings
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }
    
    var text: String {
        if vm.gameState == .mistake {
            return "This move is in none of your selected Studies!"
        } else if vm.gameState == .endOfLine {
            return "This was the last move in this Study"
        } else {
            return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let layout = isLandscape(in: geo.size) ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
                layout {
                    if !isLandscape(in: geo.size) && geo.size.width <= geo.size.height - 205 {
                        Text(text)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(height: 20)
                            .padding()
                            .opacity((vm.gameState == .mistake || vm.gameState == .endOfLine) ? 1 : 0)
                    }
                    Spacer(minLength: 0)
                    ChessboardView(vm: vm, settings: settings)
                        .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        .if(!isLandscape(in: geo.size)) { view in
                            view.frame(height: min(geo.size.width, max(geo.size.height - 143, 200)))
                        }
                        .if(isLandscape(in: geo.size)) { view in
                            view
                                .frame(width: geo.size.height)
                                .padding(.leading, 10)
                        }
                    VStack {
                        if isLandscape(in: geo.size) {
                            Spacer()
                        }
                        if isLandscape(in: geo.size) {
                            MoveGridView(vm: vm)
                            Text(text)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .frame(height: 20)
                                .padding()
                                .opacity((vm.gameState == .mistake || vm.gameState == .endOfLine) ? 1 : 0)
                        } else {
                            if geo.size.width > geo.size.height - 205 && (vm.gameState == .mistake || vm.gameState == .endOfLine) {
                                Text(text)
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.center)
                                    .frame(height: 40)
                                    .padding(.vertical, 7)
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
                            HStack(spacing: 15) {
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
                                }
                                .disabled(vm.positionIndex == 0)
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
                                }
                                .disabled(vm.gameState != .idle)
                            }
                            HStack {
                                Spacer()
                                if vm.currentQueueIndex == nil {
                                    Button() {
                                        vm.reset()
                                    } label: {
                                        HStack {
                                            if geo.size.height < 400 && geo.size.width < 700 {
                                                Text("Reset")
                                            } else {
                                                Text("Reset to start")
                                            }
                                            Image(systemName: "arrow.counterclockwise")
                                                .resizable()
                                                .scaledToFit()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button() {
                                        vm.nextQueueItem()
                                    } label: {
                                        HStack {
                                            Text("Next Position")
                                            Image(systemName: "arrowshape.right")
                                                .resizable()
                                                .scaledToFit()
                                        }
                                    }
                                    .disabled((vm.currentQueueIndex ?? 0) + 1 == vm.queueItems.count)
                                    .buttonStyle(.bordered)
                                    
                                }
                            }
                        }
                        .frame(height: 50)
                        .padding(.vertical, 10)
                        .padding(.trailing, 10)
                        .if(!isLandscape(in: geo.size)) { view in
                            view.padding(.leading, 10)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .if(verticalSizeClass == .compact) { view in
                    view.navigationBarTitleDisplayMode(.inline)
                }
                .sheet(isPresented: $showingSelectView) {
                    SelectStudyView(gametrees: self.database.gametrees, vm: vm)
                }
                
                .navigationTitle(Text(self.vm.selectedGameTrees.first?.name ?? "Practice"))
                
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button() {
                            transitionToExploreView()
                        } label: {
                            HStack {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text("Review in Explorer")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
//                    ToolbarItem() {
//                        Menu {
//                            Button() {
//                                transitionToExploreView()
//                            } label: {
//                                HStack {
//                                    Image(systemName: "arrowshape.turn.up.left")
//                                    Text("Review in Explorer")
//                                }
//                            }
//                            Button() {
//                                vm.reset()
//                            } label: {
//                                HStack {
//                                    Image(systemName: "arrow.counterclockwise")
//                                        .resizable()
//                                        .scaledToFit()
//                                    Text("Practice from start")
//                                        .fixedSize(horizontal: false, vertical: true)
//                                        .multilineTextAlignment(.leading)
//
//                                }
//                            }
//                        } label: {
//                            Image(systemName: "ellipsis.circle")
//                        }
//                    }
                    ToolbarItem() {
                        Button() {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
            .onAppear() {
                vm.onAppear()
            }
        }
    }
    func isLandscape(in size: CGSize) -> Bool {
        size.width > size.height
    }
    
    func transitionToExploreView() {
        guard let selectedGameTree = self.vm.selectedGameTrees.first else { return }
        guard var currentNode = vm.currentNodes.first else { return }
        appControl.vm_ExploreView.reset(to: selectedGameTree)
        appControl.vm_ExploreView.game = vm.game
        appControl.vm_ExploreView.moveHistory = vm.moveHistory
        appControl.vm_ExploreView.positionHistory = vm.positionHistory
        appControl.vm_ExploreView.positionIndex = vm.positionIndex
        appControl.vm_ExploreView.userColor = vm.userColor
        var currentExploreNode = ExploreNode(gameNode: currentNode, color: currentNode.nextMoveColor)
        
        appControl.vm_ExploreView.currentExploreNode = currentExploreNode

        while true {
            guard let parentMoveNode = currentNode.parents.first else { break }
            guard let parentNode = parentMoveNode.parent else { break }
            currentExploreNode.move = parentMoveNode.moveString
            let parentExploreNode = ExploreNode(gameNode: parentNode, color: parentNode.nextMoveColor)
            currentExploreNode.parent = parentExploreNode
            parentExploreNode.children = [currentExploreNode]

            currentExploreNode = parentExploreNode
            currentNode = parentNode
        }

        if vm.gameState == .mistake {
            guard let lastPosition = vm.positionHistory.last else { return }
            guard let lastMoveString = vm.moveHistory.last?.1 else { return }
            
            let newExploreNode = ExploreNode(move: lastMoveString, parentNode: appControl.vm_ExploreView.currentExploreNode, position: lastPosition, color: vm.userColor.negotiated)
            appControl.vm_ExploreView.currentExploreNode.children = [newExploreNode]
            appControl.vm_ExploreView.currentExploreNode = newExploreNode
        }
        
        var indexDiff = vm.moveHistory.count - vm.positionIndex - 1
        while indexDiff > 0 {
            guard let parent = appControl.vm_ExploreView.currentExploreNode.parent else { return }
            appControl.vm_ExploreView.currentExploreNode = parent
            indexDiff -= 1
        }
        
        appControl.vm_ExploreView.rootExploreNode = currentExploreNode

        appControl.vm_ExploreView.postMoveStuff()
        appControl.selectedTab = 0
        dismiss()
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        let database = DataBase()
        PracticeView(database: database, settings: Settings(), vm: PracticeViewModel(database: database, settings: Settings()))
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
        PracticeView(database: database, settings: Settings(), vm: PracticeViewModel(database: database, settings: Settings()))
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation))"))
        PracticeView(database: database, settings: Settings(), vm: PracticeViewModel(database: database, settings: Settings()))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
    }
}
