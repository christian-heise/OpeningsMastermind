//
//  SortingMethods.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 08.05.23.
//

import Foundation

enum SortingMethod: String, Codable, Hashable, CaseIterable {
    case date = "Date"
    case name = "Name"
    case manual = "Manual"
    case progress = "Progress"
}
