//
//  Extension.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 25.04.23.
//

import Foundation
import SwiftUI
import ChessKit


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


extension Image {
    static func piece(color: PieceColor, kind: PieceKind) -> Image {
        switch kind {
        case .bishop:
            return color == .white ? Image("Chess_blt45.svg") : Image("Chess_bdt45.svg")
        case .knight:
            return color == .white ? Image("Chess_nlt45.svg") : Image("Chess_ndt45.svg")
        case .king:
            return color == .white ? Image("Chess_klt45.svg") : Image("Chess_kdt45.svg")
        case .queen:
            return color == .white ? Image("Chess_qlt45.svg") : Image("Chess_qdt45.svg")
        case .pawn:
            return color == .white ? Image("Chess_plt45.svg") : Image("Chess_pdt45.svg")
        case .rook:
            return color == .white ? Image("Chess_rlt45.svg") : Image("Chess_rdt45.svg")
        }
    }
}
