//
//  PracticeCenterView.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 13.06.23.
//

import SwiftUI
import ChessKit

struct PracticeCenterView: View {
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings
    
    @StateObject var vm: PracticeCenterViewModel
    @StateObject var vm_child: PracticeViewModel
    
    @State private var isShowingModal = false
//    @State private var selectedQueueItem: QueueItem?
    
    init(database: DataBase, settings: Settings) {
        self._vm_child = StateObject(wrappedValue: PracticeViewModel(database: database))
        self._vm = StateObject(wrappedValue: PracticeCenterViewModel(database: database))
        self.database = database
        self.settings = settings
    }
    
    let size: CGFloat = 120
    var body: some View {
        NavigationStack {
            VStack {
                if !vm.queueItems.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Up next")
                                .font(.title2)
                                .padding(.horizontal)
                                .padding(.top)
                            Spacer()
                            Button() {
                                
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .padding(15)
                        }
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(vm.queueItems, id: \.gameNode.id) { queueItem in
                                    VStack {
                                        ChessboardView(vm: DisplayBoardViewModel(annotation: (nil,nil), userColor: queueItem.gameTree.userColor, currentMoveColor: queueItem.gameNode.parents.first?.moveColor ?? .white, position: FenSerialization.default.deserialize(fen: queueItem.gameNode.fen)), settings: settings)
                                            .rotationEffect(.degrees(queueItem.gameTree.userColor == .white ? 0 : 180))
                                            .frame(height: size)
                                        Text("Mistakes: \(queueItem.gameNode.mistakesSum)")
                                        Text("Nodes below: \(queueItem.gameNode.nodesBelow)")
                                        Text(queueItem.gameTree.name)
                                            .buttonStyle(.plain)
                                    }
                                    .frame(width: size)
                                    .onTapGesture {
                                        tappedItem(queueItem: queueItem)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom)
                        .scrollIndicators(.hidden)
                    }
                    
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .opacity(0.1)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .opacity(0.1)
                    VStack(alignment: .leading) {
                        Text("Practice specific opening")
                            .font(.title2)
                            .padding(.horizontal)
                            .padding(.top)
                        ScrollView(showsIndicators: true) {
                            VStack(alignment: .leading) {
                                ForEach(database.gametrees, id: \.self) { tree in
                                    HStack() {
                                        Text(tree.name)
                                            .padding(.vertical, 10)
                                            .padding(.leading, 15)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .padding(.trailing, 15)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        RoundedRectangle(cornerRadius: 5)
                                            .opacity(0.2)
                                    }
                                    .padding(.bottom, 5)
                                    .onTapGesture {
                                        self.tappedTree(tree: tree)
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.never)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
//                        .background() {
//                            RoundedRectangle(cornerRadius: 10).fill(Color.mint)
//                        }

                    }
//                    .padding()
                }
            }
            .padding()
            .navigationTitle("Practice Center")
            .onAppear() {
                vm.getQueueItems()
            }
            .fullScreenCover(isPresented: $isShowingModal, onDismiss: didDismiss) {
                PracticeView(database: database, settings: Settings(), vm: vm_child)
            }
        }
    }
    func tappedItem(queueItem: QueueItem) {
        self.vm_child.currentNodes = [queueItem.gameNode]
        self.vm_child.selectedGameTrees = Set([queueItem.gameTree])
        self.vm_child.game = Game(position: FenSerialization.default.deserialize(fen: queueItem.gameNode.fen))
        self.vm_child.gameState = .idle
        self.vm_child.userColor = queueItem.gameTree.userColor
//        self.vm_child.startingMove = (queueItem.gameNode.parents.first?.halfMoveNumber ?? 0)
        print(self.vm_child.startingMove)
        
        var moveHistory: [(Move, String)] = []
        var positionHistory: [Position] = []
        var currentNode = queueItem.gameNode
        
        positionHistory.append(FenSerialization.default.deserialize(fen: currentNode.fen))
        
        while true {
            guard let parentMove = currentNode.parents.first  else { break }
            moveHistory.insert((parentMove.move, parentMove.moveString), at: 0)
            guard let parentNode = parentMove.parent else {
                moveHistory = []
                positionHistory = []
                break
            }
            positionHistory.insert(FenSerialization.default.deserialize(fen: parentNode.fen), at: 0)
            currentNode = parentNode
        }
        self.vm_child.moveHistory = moveHistory
        self.vm_child.positionHistory = positionHistory
        self.vm_child.positionIndex = (queueItem.gameNode.parents.first?.halfMoveNumber ?? 0) - 1
        self.isShowingModal = true
    }
    func tappedTree(tree: GameTree) {
        self.vm_child.selectedGameTrees = Set([tree])
        self.vm_child.reset()
        self.isShowingModal = true
    }
    func didDismiss() {
        self.vm_child.reset()
        self.vm.getQueueItems()
    }
}

struct PracticeCenterView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeCenterView(database: DataBase(), settings: Settings())
    }
}
