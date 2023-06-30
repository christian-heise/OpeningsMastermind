//
//  AppControlViewModel.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 23.06.23.
//

import Foundation


final class AppControlViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var vm_ExploreView: ExploreViewModel
    
    init(vm_ExploreView: ExploreViewModel) {
        self.vm_ExploreView = vm_ExploreView
    }
    
    
}
