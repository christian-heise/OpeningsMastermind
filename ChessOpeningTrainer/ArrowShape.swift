//
//  ArrowShape.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 21.04.23.
//

import Foundation
import SwiftUI

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var points = [CGPoint]()
        
        let arrowWidth = min(rect.maxY, CGFloat(35))
        let lineWidth = min(arrowWidth*0.5,CGFloat(15))
        let arrowLength = min(rect.maxX*0.5, CGFloat(25))
        
        // Define arrow points
        points.append(CGPoint(x: rect.minX, y: rect.midY + lineWidth/2))
        points.append(CGPoint(x: rect.minX, y: rect.midY - lineWidth/2))
        points.append(CGPoint(x: rect.maxX - arrowLength, y: rect.midY - lineWidth/2))
        points.append(CGPoint(x: rect.maxX - arrowLength, y: rect.midY - arrowWidth/2))
        points.append(CGPoint(x: rect.maxX, y: rect.midY))
        points.append(CGPoint(x: rect.maxX - arrowLength, y: rect.midY + arrowWidth/2))
        points.append(CGPoint(x: rect.maxX - arrowLength, y: rect.midY + lineWidth/2))
        
        // Create arrow path
        path.move(to: points[0])
        for i in 0..<points.count-1 {
            path.addLine(to: points[i+1])
        }
        
        return path
    }
}
