//
//  BulletList.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 26.04.23.
//

import SwiftUI

struct BulletList: View {
    var listItems: [String]
    var listItemSpacing: CGFloat? = nil
    var bullet: String = "•"
    var bulletWidth: CGFloat? = nil
    var bulletAlignment: Alignment = .leading
    
    var body: some View {
        VStack(alignment: .leading,
               spacing: listItemSpacing) {
            ForEach(listItems, id: \.self) { data in
                HStack(alignment: .top) {
                    Text(bullet)
                        .frame(width: bulletWidth,
                               alignment: bulletAlignment)
                    Text(data)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)
                }
            }
        }
    }
}

struct BulletList_Previews: PreviewProvider {
    static var previews: some View {
        BulletList(listItems: ["First Point", "Second Point"])
    }
}
