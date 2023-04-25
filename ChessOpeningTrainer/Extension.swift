//
//  Extension.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import Foundation
import SwiftUI


extension Color {
    var rgbValues: [Int] {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return [255,255,255]
        }

        return [r, g, b].map({Int(Double($0) * 255.0)})
    }
}


extension [Int] {
    func getColor() -> Color {
        if self.count == 3 {
            let rgbDouble = self.map({Double($0)/255.0})
            return Color(red: rgbDouble[0], green: rgbDouble[1], blue: rgbDouble[2])
        } else {
            return Color.red
        }
    }
}
