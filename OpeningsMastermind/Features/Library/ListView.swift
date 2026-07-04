//
//  ListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var database: DataBase
    
    @State private var showingAddSheet = false
    
    @State private var isLoading = false
    
    @State private var pgnString: String = ""

    @State private var importProblemText = ""

    @State private var showingImportProblem = false
    
    var sortedGameTrees: [GameTree] {
        let ascending = database.sortingDirectionIncreasing
        switch database.sortSelection {
        case .name:
            return database.gametrees.sorted {
                ascending ? $0.name < $1.name : $0.name > $1.name
            }
        case .date:
            return database.gametrees.sorted {
                if $0.dateAdded == $1.dateAdded {
                    return ascending ? $0.name > $1.name : $0.name < $1.name
                }
                return ascending ? $0.dateAdded > $1.dateAdded : $0.dateAdded < $1.dateAdded
            }
        case .progress:
            return database.gametrees.sorted {
                ascending ? $0.progress > $1.progress : $0.progress < $1.progress
            }
        case .manual:
            return database.gametrees
        case .lastPlayed:
            return database.gametrees.sorted {
                ascending ? $0.dateLastPlayed > $1.dateLastPlayed : $0.dateLastPlayed < $1.dateLastPlayed
            }
        }
    }
    
    private var sortSelectionBinding: Binding<SortingMethod> {
        Binding<SortingMethod>(
            get: {
                database.sortSelection
            },
            set: {
                if $0 == database.sortSelection && database.sortSelection != .manual {
                    database.sortingDirectionIncreasing.toggle()
                } else {
                    database.sortingDirectionIncreasing = true
                    database.sortSelection = $0
                }
            }
        )
    }

    private var sortingMenu: some View {
        Menu("Select sorting method", systemImage: "line.3.horizontal.decrease.circle") {
            Picker("Sorting options", selection: sortSelectionBinding) {
                ForEach(SortingMethod.allCases, id: \.self) { sortingMethod in
                    HStack {
                        Text(sortingMethod.rawValue)
                        if database.sortSelection == sortingMethod && sortingMethod != .manual {
                            Image(systemName: database.sortingDirectionIncreasing ? "chevron.down" : "chevron.up")
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if database.gametrees.isEmpty {
                    ContentUnavailableView {
                        Label("No Studies Yet", systemImage: "books.vertical")
                    } description: {
                        Text("Add a PGN file or import a study to get started.")
                    } actions: {
                        Button("Add Study") {
                            showingAddSheet = true
                        }
                    }
                } else {
                    List {
                        ForEach(sortedGameTrees, id: \.self) { gameTree in
                            VStack(alignment: .leading) {
                                Text(gameTree.name)
                                    .fontWeight(.medium)
                                HStack {
                                    Text("Progress:")
                                    ProgressBarView(progress: gameTree.progress)
                                        .frame(height: 20)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                        .onMove(perform: move)
                    }
                }
            }
            .navigationTitle("Opening Studies")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem {
                    sortingMenu
                }
                ToolbarItem() {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Open Add Study Sheet", systemImage: "plus") {
                            showingAddSheet = true
                        }
                        .accessibilityIdentifier("library.addStudyButton")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddStudyView(database: database, isLoading: $isLoading, pgnString: $pgnString)
            }
            .alert(importProblemText, isPresented: $showingImportProblem) { }

        }
        .onOpenURL { deepLinkURL in
            self.addStudyFromDeeplink(deepLinkURL)
        }
        #if DEBUG
        .onAppear {
            if let pgn = UITestSupport.prefilledPGN, pgnString.isEmpty {
                pgnString = pgn
            }
        }
        #endif
    }
    
    func delete(at offsets: IndexSet) {
        let array = Array(offsets)
        for i in array {
            let deleteIndex = IndexSet(integer: database.gametrees.firstIndex(where: {$0 == sortedGameTrees[i]}) ?? .zero)
            database.removeGameTree(at: deleteIndex)
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        database.gametrees.move(fromOffsets: source, toOffset: destination)
        database.sortSelection = .manual
    }
    
    func addStudyFromDeeplink(_ deepLinkURL: URL) {
        guard let components = URLComponents(url: deepLinkURL, resolvingAgainstBaseURL: true),
              let queryItem = components.queryItems?.first(where: { $0.name == "share_url" })?.value else {
            return
        }
        self.isLoading = true
        Task {
            do {
                let pgnString = try await LichessStudyService.pgn(fromStudyURL: queryItem)
                await MainActor.run() {
                    self.pgnString = pgnString
                    self.showingAddSheet = true
                    self.isLoading = false
                }
            } catch let localError {
                await MainActor.run {
                    self.isLoading = false
                    switch localError {
                    case LichessPGNError.urlInvalid:
                        importProblemText = "The provided URL is not valid."
                    case LichessPGNError.noLichessUrl:
                        importProblemText = "The provided URL is not a lichess.com URL."
                    default:
                        importProblemText = "A problem occured while downloading. Please try again later."
                    }
                    showingImportProblem = true
                }
            }
        }
    }
}

#Preview {
    ListView(database: DataBase())
        .environment(AppData())
}
