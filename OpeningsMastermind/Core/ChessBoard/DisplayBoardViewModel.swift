//
//  DisplayBoardViewModel.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 13.06.23.
//

import Foundation
import ChessKit

class DisplayBoardViewModel: ParentChessBoardModel, ParentChessBoardModelProtocol {
    var annotation: (String?, String?)
    
    var userColor: ChessKit.PieceColor
    
    var currentMoveColor: ChessKit.PieceColor
    
    init(annotation: (String?, String?), userColor: ChessKit.PieceColor, currentMoveColor: ChessKit.PieceColor, position: Position) {
        self.annotation = annotation
        self.userColor = userColor
        self.currentMoveColor = currentMoveColor
        
        super.init()
        
        self.game = Game(position: position)
        self.gameState = .view
    }
    
    func reset() {
    }
    
    func jump(to index: Int) {
    }
    
}
