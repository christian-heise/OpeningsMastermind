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
    let mate: Int?
    
    var text: String {
        if let mate = mate {
            if mate == 0 {
                if eval ?? 10 > 0 {
                    return "1-0"
                } else {
                    return "0-0"
                }
            } else {
                return "Mate in \(abs(mate))"
            }
        } else if let evaluation = self.eval {
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
            VStack {
                ZStack {
                    
                    Rectangle().fill([50,50,50].getColor())
                        .frame(height: geo.size.height / 2 * (1 - max(min(eval ?? 0, 10), -10)/10))
                        .position(CGPoint(x: geo.size.width / 2, y: geo.size.height / 4 * (1 - max(min(eval ?? 0, 10), -10)/10)))
                        .animation(.linear(duration: 1) .delay(0.1), value: eval ?? 0)
                    Rectangle().fill([230,230,230].getColor())
                        .frame(height: geo.size.height / 2 * (1 + max(min(eval ?? 0, 10), -10)/10))
                        .position(CGPoint(x: geo.size.width / 2, y: geo.size.height / 4 * (3 - max(min(eval ?? 0, 10), -10)/10)))
                        .animation(.linear(duration: 1) .delay(0.1), value: eval ?? 0)
                    Rectangle().stroke(.black)
                    VStack {
                        if eval ?? 0 <= -7 {
                            Text(text)
                                .font(.system(size: 8, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        if eval ?? 0 > -7 {
                            Text(text)
                                .font(.system(size: 8, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
    }
}

struct EvalBarView_Previews: PreviewProvider {
    static var previews: some View {
        EvalBarView(eval: 0, mate: nil)
            .frame(width: 20, height: 200)
    }
}
