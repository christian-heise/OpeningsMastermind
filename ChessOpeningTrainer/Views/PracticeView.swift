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
    
    @StateObject var vm: PracticeViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    var landscape: Bool {
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }

    init(database: DataBase, settings: Settings, gameTree: GameTree) {
        self._vm = StateObject(wrappedValue: PracticeViewModel(gameTree: gameTree))
        self.database = database
        self.settings = settings
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
    
    var body: some View {
        let layout = landscape ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
        NavigationStack {
            GeometryReader { geo in
                layout {
                    if !landscape {
                        Spacer()
                        Text(text)
                            .font(.headline)
                            .frame(height: 20)
                            .padding()
                            .opacity(vm.gameState > 0 ? 1 : 0)
                    }
                    ChessboardView(vm: vm, settings: settings)
                        .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        .if(!landscape) { view in
                            view.frame(height: min(geo.size.width, max(geo.size.height - 50 - 40 - 85, 300)))
                                
                        }
                        .if(landscape) { view in
                            view.padding(.horizontal)
                        }
                    VStack {
                        if landscape {
                            Spacer()
                        }
                        MoveListView(vm: vm)
                            .padding(.vertical, 7)
                            .padding(.trailing, 7)
                            .background(){
                                Color.gray.opacity(0.1)
                                    .shadow(radius: 5)
                            }
                            
                        if landscape {
                            Text(text)
                                .font(.headline)
                                .frame(height: 20)
                                .padding()
                                .opacity(vm.gameState > 0 ? 1 : 0)
                        }
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
                                vm.reset()
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
                    .if(landscape) { view in
                        view.frame(width: geo.size.width/3)
                    }
                }
                .onRotate { newOrientation in
                    orientation = newOrientation
                }
                .navigationTitle(vm.gameTree.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(){self.presentationMode.wrappedValue.dismiss()} label: {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .fontWeight(.semibold)
                                Text("Back")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView(database: DataBase(), settings: Settings(), gameTree: GameTree.example())
    }
}
