//
//  PawnPromotionView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 06.05.23.
//

import SwiftUI
import ChessKit

struct PawnPromotionView: View {
    let color: PieceColor
    let width: CGFloat
    
    @EnvironmentObject var vm: PractiseViewModel
    
    let pieceKinds: [PieceKind] = [.queen, .rook, .knight ,.bishop]
    var body: some View {
        HStack {
            Group {
                ForEach(pieceKinds, id: \.self) { kind in
                    Button {
                        vm.processPromotion(kind)
                    } label: {
                        Image.piece(color: color, kind: kind)
                            .pawnPromotionPiece(width:width, height:width)
                    }
                }
                
            }
        }
        .padding(5)
        .background() {
            RoundedRectangle(cornerRadius: 5).stroke()
            RoundedRectangle(cornerRadius: 5).fill(Color.black)
                .shadow(radius: 20)
        }
        
    }
}

struct PawnPromotionView_Previews: PreviewProvider {
    static var previews: some View {
        PawnPromotionView(color: .white, width: 70)
    }
}

extension Image {
    func pawnPromotionPiece(width: CGFloat, height: CGFloat) -> some View {
        self
            .resizable()
            .frame(width: width, height: height, alignment: .center)
            .background() {
                RoundedRectangle(cornerRadius: 5).stroke()
                RoundedRectangle(cornerRadius: 5).fill(Color.white)
            }
    }
}
