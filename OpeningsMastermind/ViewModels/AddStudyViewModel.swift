//
//  AddStudyViewModel.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 29.08.23.
//

import Foundation


@MainActor class AddStudyViewModel: ObservableObject {
    
    
    var nameString = ""
    var selectedColor = "white"
    var lichessURL = ""
    var importProblemText = ""
    
    var nameError = false
    var pgnError = false
    var duplicateError = false
    
    var showingPGNHelp = false
    var showingLichessAlert = false
    var showingImportProblem = false
    
    var examplePicker = 0
    
    var exampleSelection = Set<ExamplePGN>()
}
