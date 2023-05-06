//
//  PractiseView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI
import ChessKit

struct PractiseView: View {
    @StateObject private var vm = PractiseViewModel()
    @ObservedObject var settings: Settings
    
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
        NavigationView {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    ChessboardViewNew(settings: settings)
                        .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        .frame(maxHeight: geo.size.width)
                    Spacer()
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
                    Text("Mistake Rate: \(String(format: "%0.2f",vm.gameTree?.currentNode?.mistakesRate ?? 0.0))")
                }
                .environmentObject(vm)
                .navigationTitle(Text(vm.gameTree?.name ?? "No study"))
            }
            .onAppear() {
                self.vm.gameTree = ExamplePGN.list[3].gameTree
            }
            .toolbar {
                ToolbarItem {
                    
                }
            }
        }
    }
}

struct PractiseView_Previews: PreviewProvider {
    static var previews: some View {
        PractiseView(settings: Settings())
    }
}
