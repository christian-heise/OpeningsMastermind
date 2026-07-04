//
//  ProgressBarView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 07.05.23.
//

import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    
    var text: String {
        if progress > 0 && progress < 0.005 {
            return "< 1%"
        } else {
            return "\(Int(round(progress*100)))%"
        }
    }
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(.green)
                                .mask(
                                    RoundedRectangle(cornerRadius: 5)
                                        .frame(width: barWidth(in: geo.size))
                                        .position(CGPoint(x: barWidth(in: geo.size)/2, y: geo.size.height/2))
                                )
                                .zIndex(10)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray)
                                .zIndex(0)
                                .opacity(0.15)
                        }
                    )
                Text(text)
                    .foregroundColor(progress > 0.6 ? .white : .green)
                    .position(progress > 0.6 ? CGPoint(x: barWidth(in: geo.size) - 30, y: geo.size.height/2) : CGPoint(x: barWidth(in: geo.size) + 30, y: geo.size.height/2))
                    .fontWeight(.bold)
            }
        }
    }
    
    func barWidth(in size: CGSize) -> CGFloat {
        if progress == 0 {
            return 0
        } else {
            return max(size.width * CGFloat(progress), 3)
        }
    }
}

struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(progress: 0.2)
            .frame(height: 100)
            .padding()
    }
}
