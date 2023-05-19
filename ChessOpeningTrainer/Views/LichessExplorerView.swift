//
//  LichessExplorerView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 19.05.23.
//

import SwiftUI

struct LichessExplorerView: View {
    let openingData: LichessOpeningData?
    
    var body: some View {
        HStack {
            VStack(alignment: .trailing) {
                ForEach(openingData?.moves ?? [], id: \.self) { move in
                    Text(move.san)
                        .frame(height: 20)
                }
            }
            VStack(alignment: .trailing) {
                ForEach(openingData?.moves ?? [], id: \.self) { move in
                    Text(String(move.white + move.draws + move.black))
                        .font(.system(size: 14, design: .monospaced))
                        .frame(height: 20)
                }
            }
            VStack {
                ForEach(openingData?.moves ?? [], id: \.self) { move in
                    ZStack {
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                ZStack {
                                    Rectangle()
                                        .fill([207, 199, 207].getColor())
                                        .frame(width: geo.size.width * CGFloat(move.white)/CGFloat(move.white + move.black + move.draws))
                                    Text(String(format:"%.0f%%", Double(move.white)/Double(move.white + move.black + move.draws)*100))
                                }
                                ZStack {
                                    Rectangle()
                                        .fill([128, 108, 128].getColor())
                                        .frame(width: geo.size.width * CGFloat(move.draws)/CGFloat(move.white + move.black + move.draws))
                                    Text(String(format:"%.0f%%", Double(move.draws)/Double(move.white + move.black + move.draws)*100))
                                }
                                ZStack {
                                    Rectangle()
                                        .fill([36, 30, 36].getColor())
                                        .frame(width: geo.size.width * CGFloat(move.black)/CGFloat(move.white + move.black + move.draws))
                                    Text(String(format:"%.0f%%", Double(move.black)/Double(move.white + move.black + move.draws)*100))
                                        .foregroundColor([239, 235, 239].getColor())
                                }
                            }
                        }
                        Rectangle().stroke()
                    }
                    .frame(height: 20)
                }
            }
        }
    }
}

struct LichessExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        LichessExplorerView(openingData: LichessOpeningData.example)
    }
}
