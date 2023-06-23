//
//  MoveListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import SwiftUI
import ChessKit

struct MoveListView<ParentVM>: View where ParentVM: ParentChessBoardModelProtocol {
    @ObservedObject var vm: ParentVM
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { value in
                HStack {
                    ForEach(0..<vm.moveHistory.count, id: \.self) { preindex in
                        let index = vm.moveHistory.count - preindex - 1
                        HStack {
                            if (index + vm.startingMove)%2 == 0 {
                                Text("\((index + vm.startingMove)/2+1).")
                            }
                            Button {
                                vm.jump(to: index)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(vm.positionIndex == index ? (colorScheme == .light ? [76,76,76].getColor() : [200,200,200].getColor()) : (colorScheme == .light ? [202,202,202].getColor() : [100,100,100].getColor()))
                                    Text(vm.moveHistory[index].1)
                                        .foregroundColor(vm.positionIndex == index ? (colorScheme == .light ? .white : .black) : (colorScheme == .light ? .black : .white))
                                }
                                .frame(width: 60)
                            }
                            .disabled(vm is PracticeViewModel)
                        }
                        .rotationEffect(Angle(radians: .pi))
                    }
                    .onChange(of: vm.positionIndex) { _ in
                        value.scrollTo(vm.moveHistory.count - vm.positionIndex - 1)
                    }
                }
                .frame(height: 40)
            }
        }
        .rotationEffect(Angle(radians: .pi))
    }
}

struct MoveListView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView(database: DataBase(), settings: Settings())
    }
}
