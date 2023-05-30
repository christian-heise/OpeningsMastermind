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

    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @State private var showingSelectView = false

    init(database: DataBase, settings: Settings, gameTree: GameTree) {
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
        NavigationStack {
            GeometryReader { geo in
                let layout = isLandscape(in: geo.size) ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
                layout {
                    if !isLandscape(in: geo.size) && geo.size.width <= geo.size.height - 205 {
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
                        .if(!isLandscape(in: geo.size)) { view in
                            view.frame(height: min(geo.size.width, max(geo.size.height - 143, 200)))
                        }
                        .if(isLandscape(in: geo.size)) { view in
                            view
                                .frame(width: geo.size.height)
                                .padding(.horizontal)
                        }
                    VStack {
                        if isLandscape(in: geo.size) {
                            Spacer()
                        }
                        MoveListView(vm: vm)
                            .padding(.vertical, 7)
                            .padding(.trailing, 7)
                            .background(){
                                Color.gray.opacity(0.1)
                                    .shadow(radius: 5)
                            }
                            
                        if isLandscape(in: geo.size) {
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
                    .if(isLandscape(in: geo.size)) { view in
                        view.padding(.trailing)
                    }
                    
                }
                .if(verticalSizeClass == .compact) { view in
                    view.navigationBarTitleDisplayMode(.inline)
                }
                .sheet(isPresented: $showingSelectView) {
                    SelectStudyView(gametrees: self.database.gametrees, vm: vm)
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
    func isLandscape(in size: CGSize) -> Bool {
        size.width > size.height
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
//        PracticeView(database: DataBase(), settings: Settings(), gameTree: GameTree.example())
        ContentView()
    }
}
