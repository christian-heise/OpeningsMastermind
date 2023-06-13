//
//  PracticeCenterView.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 13.06.23.
//

import SwiftUI

struct PracticeCenterView: View {
    @ObservedObject var database: DataBase
    
    let size: CGFloat = 120
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("Repeat positions where a mistake was made")
                        .font(.title2)
                        .padding(.horizontal)
                        .padding(.top)
                    ScrollView(.horizontal) {
                        HStack {
                            ChessboardView(vm: DisplayBoardViewModel(annotation: (nil,nil), userColor: .white, currentMoveColor: .white, position: startingGamePosition), settings: Settings())
                                .frame(width: size, height: size)
                            ChessboardView(vm: DisplayBoardViewModel(annotation: (nil,nil), userColor: .white, currentMoveColor: .white, position: startingGamePosition), settings: Settings())
                                .frame(width: size, height: size)
                            ChessboardView(vm: DisplayBoardViewModel(annotation: (nil,nil), userColor: .white, currentMoveColor: .white, position: startingGamePosition), settings: Settings())
                                .frame(width: size, height: size)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: size, height: size)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: size, height: size)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: size, height: size)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: size, height: size)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: size, height: size)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: size, height: size)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .opacity(0.1)
                    VStack(alignment: .leading) {
                        Text("Practice a certain opening")
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
        }
    }
}

struct PracticeCenterView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeCenterView(database: DataBase())
    }
}
