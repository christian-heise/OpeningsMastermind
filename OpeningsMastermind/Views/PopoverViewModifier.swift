//
//  PopoverViewModifier.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 29.06.23.
//

import SwiftUI

struct PopoverModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}

extension View {
    func truePopover() -> some View {
        modifier(PopoverModifier())
    }
}
