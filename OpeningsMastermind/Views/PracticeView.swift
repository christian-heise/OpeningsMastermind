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
    
    @State private var showingSelectView = false
    
    var landscape: Bool {
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }

    init(database: DataBase, settings: Settings) {
        self._vm = StateObject(wrappedValue: PracticeViewModel(database: database))
        self.database = database
        self.settings = settings
    }
    
    var text: String {
        if vm.gameState == 1 {
            return "This move is in none of your selected Studies!"
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
                    if !landscape && geo.size.width <= geo.size.height - 205 {
                        Spacer()
                        Text(text)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(height: 20)
                            .padding()
                            .opacity(vm.gameState > 0 ? 1 : 0)
                    }
                    ChessboardView(vm: vm, settings: settings)
                        .rotationEffect(.degrees(vm.userColor == .white ? 0 : 180))
                        .if(!landscape) { view in
                            view.frame(height: min(geo.size.width, max(geo.size.height - 143, 200)))
                        }
                        .if(landscape) { view in
                            view
                                .frame(width: geo.size.height)
                                .padding(.horizontal)
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
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .frame(height: 20)
                                .padding()
                                .opacity(vm.gameState > 0 ? 1 : 0)
                        }
                        HStack {
                            Button(action: {
                                vm.reset()
                            }) {
                                Text("Restart Practice")
                                    .padding()
                                    .foregroundColor(.white)
                                    .background([79,147,206].getColor())
                                    .cornerRadius(10)
                            }
                            .opacity(vm.gameState >= 0 ? 1 : 0)
                            .disabled(vm.gameState >= 0 ? false : true)
    
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
                        }
                        .padding(10)
                    }
                    .if(landscape) { view in
                        view.padding(.trailing)
                    }
                }
                .sheet(isPresented: $showingSelectView) {
                    SelectStudyView(gametrees: self.database.gametrees, vm: vm)
                }
                .onRotate { newOrientation in
                    if newOrientation == .landscapeLeft || newOrientation == .landscapeRight || newOrientation == .portrait || newOrientation == .portraitUpsideDown {
                        orientation = newOrientation
                    }
                }
                .if(landscape) { view in
                    view.navigationBarTitleDisplayMode(.inline)
                }
                .onAppear() {
                    vm.onAppear()
                }
                .navigationTitle("Practice")
                .toolbar {
                    ToolbarItem() {
                        Button() {
                            showingSelectView = true
                        } label: {
                            HStack {
                                if vm.selectedGameTrees.count > 1 {
                                    Text("\(vm.selectedGameTrees.count) Studies selected")
                                } else if vm.selectedGameTrees.count == 1 {
                                    Text("„\(vm.selectedGameTrees.first!.name)“ selected")
                                } else {
                                    Text("Select Studies")
                                }
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .padding(.vertical, 1)
                            .padding(.trailing, 5)
                        }
                        .disabled(database.gametrees.isEmpty || vm.gameState == 0)
                        .background() {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray)
                                .shadow(radius: 5)
                                .opacity(0.2)
                        }
                    }
                }
            }
        }
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
//        PracticeView(database: DataBase(), settings: Settings(), gameTree: GameTree.example())
        ContentView()
    }
}
