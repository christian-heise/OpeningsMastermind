//
//  CustomToggle.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 30.08.23.
//

import SwiftUI

struct WhitePieceToggleStyle: ToggleStyle {
 
    var imageOn: Image = Image("Chess_plt45.svg")
    var imageOff: Image = Image("Chess_pdt45.svg")
    var activeColor: Color = [200,200,200].getColor()
    var passiveColor: Color = [5,5,5].getColor()
 
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
 
            Spacer()
 
            RoundedRectangle(cornerRadius: 30)
                .fill(configuration.isOn ? activeColor : passiveColor)
                .overlay {
                    Circle()
                        .fill(.white)
                        .padding(3)
                        .overlay {
                            if configuration.isOn {
                                imageOn
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 20)
                            } else {
                                imageOff
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 20)
                            }
                        }
                        .offset(x: configuration.isOn ? -10 : 10)
                }
                .frame(width: 50, height: 32)
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
