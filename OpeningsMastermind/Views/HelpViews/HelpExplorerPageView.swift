//
//  HelpExplorerPageView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 20.05.23.
//

import SwiftUI

struct HelpExplorerPageView: View {
    let maskPosition: CGPoint
    let maskFrame: CGSize
    
    let text: String
    let textYPos: CGFloat
    let textXPos: CGFloat
    
    init(maskPosition: CGPoint, maskFrame: CGSize, text: String, textYPos: CGFloat, textXPos: CGFloat = 0.5) {
        self.maskPosition = maskPosition
        self.maskFrame = maskFrame
        self.text = text
        self.textYPos = textYPos
        self.textXPos = textXPos
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("explorer_example")
                    .resizable()
                    .scaledToFit()
                    .mask({RoundedRectangle(cornerRadius: 10)})
                    .overlay() {
                        GeometryReader { geoImage in
                            RoundedRectangle(cornerRadius: 10).fill(.black).opacity(0.5)
                                .reverseMask {
                                    RoundedRectangle(cornerRadius: 10).frame(width: geoImage.size.width * maskFrame.width,height: geoImage.size.height * maskFrame.height).position(CGPoint(x: geoImage.size.width * maskPosition.x, y: geoImage.size.height * maskPosition.y))
                                }
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10).stroke(.black)
                    }
                    .padding(.horizontal, 3)
                    .frame(height: geo.size.height - 50)
                    .position(CGPoint(x: geo.size.width/2,y:geo.size.height/2 - 25))

                Text(text)
                    .foregroundColor(.black)
                    .font(.title3)
                    .padding(.vertical)
                    .padding(.horizontal)
                    .background() {
                        RoundedRectangle(cornerRadius: 5).fill([224,242,247].getColor())
                            .shadow(radius: 5)
                    }
                    .frame(width: (geo.size.height - 50)/10*6)
                    .position(CGPoint(x: geo.size.width*textXPos, y: geo.size.height*textYPos))
            }
        }
    }
}

struct HelpExplorerPageView_Previews: PreviewProvider {
    static var previews: some View {
        HelpExplorerPageView(maskPosition: CGPoint(x: 0.5, y: 0.5), maskFrame: CGSize(width: 0.5, height: 0.5), text: "Test Test", textYPos: 0.33)
    }
}
