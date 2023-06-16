//
//  ListView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 05.05.23.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings
    
    @State private var showingAddSheet = false
    @State private var sortingElements: [SortingMethod] = [.name, .date, .progress, .manual]
    
    @State private var isLoading = false
    
    @State private var pgnString: String = ""
    
    var sortedGameTrees: [GameTree] {
        if database.sortSelection == .name {
            if database.sortingDirectionIncreasing {
                return database.gametrees.sorted(by: {$0.name < $1.name})
            } else {
                return database.gametrees.sorted(by: {$0.name > $1.name})
            }
        } else if database.sortSelection == .date {
            if database.sortingDirectionIncreasing {
                return database.gametrees.sorted(by: {
                    if $0.dateAdded == $1.dateAdded {
                        return $0.name > $1.name
                    }
                    return $0.dateAdded > $1.dateAdded
                })
            } else {
                return database.gametrees.sorted(by: {
                    if $0.dateAdded == $1.dateAdded {
                        return $0.name < $1.name
                    }
                    return $0.dateAdded < $1.dateAdded
                })
            }
        } else if database.sortSelection == .progress {
            if database.sortingDirectionIncreasing {
                return database.gametrees.sorted(by: {$0.progress > $1.progress})
            } else {
                return database.gametrees.sorted(by: {$0.progress < $1.progress})
            }
        }
        return database.gametrees
    }
    
    var body: some View {
        let sortSelectionBinding = Binding<SortingMethod>(
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
        
        NavigationStack {
            Group {
                List() {
                    ForEach(sortedGameTrees, id: \.self) { gameTree in
//                        NavigationLink(destination: PracticeView(database: database, settings: settings, gameTree: gameTree)) {
                            VStack(alignment: .leading) {
                                Text(gameTree.name)
                                    .fontWeight(.medium)
                                HStack {
                                    Text("Progress:")
                                    ProgressBarView(progress: gameTree.progress)
                                        .frame(height: 20)
                                }
                            }
//                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
            }
            .navigationTitle(Text("Opening Studies"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem {
                    Menu {
                        Picker(selection: sortSelectionBinding, label: Text("Sorting options")) {
                            ForEach(sortingElements, id: \.self) { sorting in
                                HStack {
                                    Text(sorting.rawValue)
                                    if database.sortSelection == sorting && sorting != .manual {
                                        Image(systemName: database.sortingDirectionIncreasing ? "chevron.down" : "chevron.up")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem() {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(action: {showingAddSheet = true}) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddStudyView(database: database, isLoading: $isLoading, pgnString: $pgnString)
            }
            
        }
        .onAppear() {
            if database.gametrees.isEmpty {
                showingAddSheet = true
            }
        }
        .onOpenURL { deepLinkURL in
            if let components = URLComponents(url: deepLinkURL, resolvingAgainstBaseURL: true),
               let queryItem = components.queryItems?.first(where: { $0.name == "share_url" })?.value,
               let _ = URL(string: queryItem) {
                self.isLoading = true
                Task {
                    do {
                        let pgnString = try await getPGNFromLichess(queryItem)
                        await MainActor.run() {
                            self.pgnString = pgnString
                            self.showingAddSheet = true
                            self.isLoading = false
                        }
                    } catch let localError { }
                }
            }
            
        }
    }
    
    func getPGNFromLichess(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw LichessPGNError.urlInvalid }
        let expectedHost = "lichess.org"
        let expectedPath = "/study/"
        
        // Check if the URL matches the expected format
        guard url.host == expectedHost, url.path.starts(with: expectedPath) else { throw LichessPGNError.noLichessUrl }
        
        // Extract the id from the URL
        let id = url.lastPathComponent
        
        guard let apiURL = URL(string: "https://lichess.org/api/study/\(id).pgn") else { throw LichessPGNError.createdUrlInvalid}
        guard let (data, _) = try? await URLSession.shared.data(from: apiURL) else { throw LichessPGNError.badResponse}
        return try String(data: data, encoding: .utf8) ?? {throw LichessPGNError.badResponse}()
    }
    enum LichessPGNError: Error {
        case urlInvalid, noLichessUrl, badResponse, createdUrlInvalid
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
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(database: DataBase(), settings: Settings())
    }
}
