//
//  EvalBarView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 21.05.23.
//

import SwiftUI
import ChessKit

struct EvalBarView: View {
    let eval: Double?
    
    init(eval: Double?, color: PieceColor) {
        if let eval = eval {
            if color == .white {
                self.eval = eval
            } else {
                self.eval = -eval
            }
        } else {
            self.eval = eval
        }
    }
    
    var evaluationString: String {
        if let evaluation = self.eval {
            if abs(evaluation) >= 10 {
                return String(format: "%.0f",round(evaluation))
            } else {
                return String(round(evaluation*10)/10)
            }
        } else {
            return "-"
        }
    }
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack {
                Rectangle().stroke(.black)
                Rectangle().fill(.black)
                    .frame(height: geo.size.height / 2 * (1 - max(min(eval ?? 0, 10), -10)/10))
                    .position(CGPoint(x: geo.size.width / 2, y: geo.size.height / 4 * (1 - max(min(eval ?? 0, 10), -10)/10)))
                    .animation(.linear(duration: 1), value: eval ?? 0)
                Rectangle().fill(.white)
                    .frame(height: geo.size.height / 2 * (1 + max(min(eval ?? 0, 10), -10)/10))
                    .position(CGPoint(x: geo.size.width / 2, y: geo.size.height / 4 * (3 - max(min(eval ?? 0, 10), -10)/10)))
                    .animation(.linear(duration: 1), value: eval ?? 0)
                if eval ?? 0 > -7 {
                    Text(evaluationString)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.black)
                        .position(CGPoint(x: geo.size.width / 2, y: geo.size.height - 10))
                } else {
                    Text(evaluationString)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white)
                        .position(CGPoint(x: geo.size.width / 2, y: 10))
                }
            }
        }
    }
}

struct EvalBarView_Previews: PreviewProvider {
    static var previews: some View {
        EvalBarView(eval: -20, color: .white)
            .frame(width: 20, height: 200)
    }
}
