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
    
    @StateObject var vm: PracticeCenterViewModel
    
    @State private var isShowingModal = false
    
    init(database: DataBase) {
        self.database = database
        self._vm = StateObject(wrappedValue: PracticeCenterViewModel(database: database))
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
                                        ChessboardView(vm: DisplayBoardViewModel(annotation: (nil,nil), userColor: queueItem.gameTree.userColor, currentMoveColor: queueItem.gameNode.parents.first?.moveColor ?? .white, position: FenSerialization.default.deserialize(fen: queueItem.gameNode.fen)), settings: Settings())
                                            .rotationEffect(.degrees(queueItem.gameTree.userColor == .white ? 0 : 180))
                                            .frame(height: size)
                                        Text("Mistakes: \(queueItem.gameNode.mistakesSum)")
                                        Text("Nodes below: \(queueItem.gameNode.nodesBelow)")
                                        Text(queueItem.gameTree.name)
                                            .buttonStyle(.plain)
                                    }
                                    .frame(width: size)
                                    .onTapGesture {
                                        self.isShowingModal = true
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
                                    NavigationLink {
                                        Text("link")
                                    } label: {
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
                                    }
                                    .buttonStyle(.plain)
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
            .fullScreenCover(isPresented: $isShowingModal) {
                PracticeView(database: database, settings: Settings())
            }
        }
    }
}

struct PracticeCenterView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeCenterView(database: DataBase())
    }
}
