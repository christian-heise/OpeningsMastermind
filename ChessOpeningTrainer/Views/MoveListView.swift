//
//  MoveListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 18.05.23.
//

import SwiftUI
import ChessKit

struct MoveListView: View {
    @ObservedObject var vm: ExploreViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { value in
                HStack {
                    ForEach(0..<vm.moveHistory.count, id: \.self) { preindex in
                        let index = vm.moveHistory.count - preindex - 1
                        HStack {
                            if index%2 == 0 {
                                Text("\(index/2+1).")
                            }
                            Button {
                                vm.jump(to: index)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(vm.positionIndex == index ? Color.black : Color.black)
                                        .opacity(vm.positionIndex == index ? 0.6 : 0.1)
                                    Text(vm.moveHistory[index].1)
                                        .foregroundColor(vm.positionIndex == index ? .white : .black)
                                }
                                .frame(width: 60)
                            }
                            
                            
                            
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
