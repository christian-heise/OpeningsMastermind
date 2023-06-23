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
    
    @Environment(\.dismiss) var dismiss

    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
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
                        Spacer()
                        Text(text)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(height: 20)
                            .padding()
                            .opacity((vm.gameState == .mistake || vm.gameState == .endOfLine) ? 1 : 0)
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
                                .opacity((vm.gameState == .mistake || vm.gameState == .endOfLine) ? 1 : 0)
                        }
                        HStack {
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
////                                Text("Restart Practice")
////                                    .padding()
////                                    .foregroundColor(.white)
////                                    .background([79,147,206].getColor())
////                                    .cornerRadius(10)
//                            }
//                            .buttonStyle(.bordered)
//                            .opacity(vm.gameState != .idle ? 1 : 0)
//                            .disabled(vm.gameState != .idle ? false : true)
                            HStack(spacing: 15) {
                                Button {
//                                    vm.reverseOneMove()
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
//                                .disabled(vm.currentExploreNode.parent == nil)
                                Button {
//                                    vm.forwardOneMove()
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
//                                .disabled(vm.currentExploreNode.children.isEmpty && vm.currentExploreNode.gameNode?.children.isEmpty ?? true)
                            }
                            HStack {
                                Spacer()
                                Button() {
                                } label: {
                                    HStack {
                                        Text("Next Item")
                                        Image(systemName: "arrowshape.right")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                }
                                .buttonStyle(.bordered)
//                                .frame(height: 40)
                            }
                        }
                        .frame(height: 50)
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
                
                .navigationTitle(Text(self.vm.selectedGameTrees.first?.name ?? "Practice"))
                
                .toolbar {
//                    ToolbarItem() {
//                        Button() {
//                        } label: {
//                            HStack {
//                                Image(systemName: "arrowshape.turn.up.left")
//                                Text("Review position in Explorer")
//                            }
//                        }
//                        .buttonStyle(.bordered)
//                    }
                    ToolbarItem() {
                        Menu {
                            Button() {
                            } label: {
                                HStack {
                                    Image(systemName: "arrowshape.turn.up.left")
                                    Text("Review in Explorer")
                                }
                            }
                            Button() {
                                vm.reset()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .resizable()
                                        .scaledToFit()
                                    Text("Practice from start")
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.leading)
                                    
                                }
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
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
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        let database = DataBase()
        PracticeView(database: database, settings: Settings(), vm: PracticeViewModel(database: database))
//        ContentView()
    }
}
