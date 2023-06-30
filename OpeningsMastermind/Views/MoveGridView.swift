//
//  MoveGridView.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 25.06.23.
//

import SwiftUI
import ChessKit

struct MoveGridView<ParentVM>: View where ParentVM: ParentChessBoardModelProtocol {
    @ObservedObject var vm: ParentVM
    
    @Environment(\.colorScheme) private var colorScheme
    
    let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
        ]
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                ScrollViewReader { value in
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<vm.moveHistory.count, id: \.self) { preindex in
                            let index = preindex
                            HStack(spacing: 5) {
                                if (index + vm.startingMove)%2 == 0 {
                                    HStack {
                                        Spacer(minLength: 0)
                                        Text("\((index + vm.startingMove)/2+1).")
                                            .monospaced()
                                    }
                                    .frame(width: 3*11)
                                }
                                Button {
                                    vm.jump(to: index)
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(vm.positionIndex == index ? (colorScheme == .light ? [76,76,76].getColor() : [200,200,200].getColor()) : (colorScheme == .light ? [202,202,202].getColor() : [100,100,100].getColor()))
                                        Text(vm.moveHistory[index].1)
                                            .minimumScaleFactor(0.8)
                                            .font(.system(size: getFontSize(size: geo.size)))
                                            .bold()
                                            .lineLimit(1)
                                            .foregroundColor(vm.positionIndex == index ? (colorScheme == .light ? .white : .black) : (colorScheme == .light ? .black : .white))
                                    }
                                }
                                .frame(width: geo.size.width/4 - 33, height: min(60, max((geo.size.width/4 - 33)*0.75, 20)))
                            }
                            .id(index)
                        }
                        .onChange(of: vm.positionIndex) { _ in
                            value.scrollTo(vm.positionIndex)
                        }
                    }
                }
            }
        }
    }
    func getFontSize(size: CGSize) -> CGFloat {
        let fontSize = size.width/27
        return min(CGFloat(20), max(fontSize, CGFloat(12)))
    }
}

struct MoveGridView_Previews: PreviewProvider {
    static var previews: some View {
        let database = DataBase()
        let settings = Settings()
//        ExploreView(database: database, settings: settings, vm: ExploreViewModel(database: database, settings: settings))
        let vm = ExploreViewModel(database: database, settings: settings)
        MoveGridView(vm: vm) 
    }
}
