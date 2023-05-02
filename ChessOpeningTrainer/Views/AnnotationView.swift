//
//  AnnotationView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 02.05.23.
//

import SwiftUI

struct AnnotationView: View {
    let annotation: String
    
    var color: Color {
        switch annotation {
        case "!!":
            return [106, 247, 252].getColor()
        case "!":
            return [119,232,3].getColor()
        case "!?":
            return [239,146,212].getColor()
        case "?!":
            return [255,230,41].getColor()
        case "?":
            return [235,132,42].getColor()
        case "??":
            return [221,0,0].getColor()
        default:
            return [0, 0, 0].getColor()
        }
    }
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(color)
//                .frame(width: 50)
            Text(annotation)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }
}

struct AnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        AnnotationView(annotation: "!!")
    }
}
