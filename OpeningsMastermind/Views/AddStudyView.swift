//
//  AddStudyView.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import SwiftUI
import ChessKit
import UniformTypeIdentifiers

struct AddStudyView: View {
    @ObservedObject var database: DataBase
    @ObservedObject var settings: Settings
    @Binding var isLoading: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var editMode = EditMode.active
    
    @Binding private var pgnString: String
    
    @State private var nameString = ""
    @State private var selectedColor = "white"
    @State private var lichessURL = ""
    @State private var importProblemText = ""
    
    @State private var nameError = false
    @State private var pgnError = false
    @State private var duplicateError = false
    
    @State private var showingPGNHelp = false
    @State private var showingLichessAlert = false
    @State private var showingImportProblem = false
    
    @State private var examplePicker = 0
    
    @State private var exampleSelection = Set<ExamplePGN>()
    @State private var lichessSelection = Set<LichessStudyMetaData>()
    
    let colors = ["white", "black"]
    
    @State private var studyList: [LichessStudyMetaData] = []
    
    @State private var colorDict: [String: Bool] = [:]
    
    init(database: DataBase, settings: Settings,  isLoading: Binding<Bool>, pgnString: Binding<String>) {
        self.database = database
        self.settings = settings
        self._isLoading = isLoading
        self._pgnString = pgnString
    }
    
    var selectedPieceColor: PieceColor {
        if self.selectedColor == "white" {
            return .white
        } else {
            return .black
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if examplePicker == 0 {
                    TextField("Name of Study", text: $nameString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).stroke(nameError ? Color.red : Color.gray, lineWidth: nameError ? 1 : 0.5)
                        )
                        .onSubmit {
                            addStudy()
                        }
                        .onTapGesture {
                            nameError = false
                        }
                        .padding(.horizontal)
                        .onChange(of: nameString) { newValue in
                            nameError = false
                        }
                    
                    VStack(alignment: .leading) {
                        Text("Select your color:")
                            .font(.headline)
                        
                        Picker("Your Piece Color", selection: $selectedColor) {
                            ForEach(colors, id:\.self) {
                                Text($0)
                            }
                        }.pickerStyle(.segmented)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    
                    VStack() {
                        HStack {
                            Text("Enter the PGN of your study:")
                                .font(.headline)
                            Button(action: {
                                self.showingPGNHelp = true
                            }) {
                                Image(systemName: "questionmark.circle")
                            }
                            .popover(isPresented: $showingPGNHelp, attachmentAnchor: .point(.center), arrowEdge: .trailing, content: {
                                Text("Paste a custom PGN, or use the button below to import a lichess study with its URL. You also have the option to choose from 5 example studies")
                                    .padding()
                                    .frame(width: 300)
                                    .truePopover()
                            })
                            Spacer()
                            Button(action: {
                                self.pgnString = ""
                            }) {
                                Image(systemName: "xmark.circle")
                            }
                        }

                            
                        TextEditor(text: _pgnString)
                            .frame(minHeight: 40)
                            .padding(4)
                            .onSubmit {
                                addStudy()
                            }
                            .onTapGesture {
                                pgnError = false
                            }
                            .autocorrectionDisabled(true)
                            .keyboardType(.asciiCapable)
                            .scrollContentBackground(.hidden)
                            .background(ZStack(alignment: .topLeading){
                                RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? .black : .white)
                                if pgnString.isEmpty {
                                    Text("Enter PGN here")
                                        .foregroundColor(.gray)
                                        .opacity(0.7)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 11)
                                        .zIndex(10)
                                }
                            }
                            )
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(pgnError ? Color.red : Color.gray, lineWidth: pgnError ? 1 : 0.5))
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if let clipboardString = UIPasteboard.general.string {
                                pgnString = clipboardString
                                pgnError = false
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste Clipboard")
                        }
//                        .padding(.horizon)
                        
                        Button() {
                            showingLichessAlert = true
                        } label: {
                            HStack{
                                Image(systemName: "square.and.arrow.down")
                                Text("Import PGN via Lichess URL")
                            }
                        }
//                        .padding()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .alert(isPresented: $showingImportProblem) {
                        Alert(title: Text(importProblemText))
                    }
                        
                    Button(action: {
                        addStudy()
                    }) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Study")
                    }
                    .foregroundColor(.green)
                    .padding(.bottom, 10)
                    .alert(isPresented: $duplicateError) {
                        Alert(title: Text("Duplicate"), message: Text("Library already contains study with this name"))
                    }
                } else if examplePicker == 1 {
                    List(selection: $lichessSelection) {
                        ForEach(studyList, id: \.self) { study in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(study.name)
                                    Text("last updated on " + dateStringFromTimestamp(study.updatedAt/1000))
                                        .font(Font.caption)
                                }
                                .opacity(database.gametrees.contains(where: {$0.name == study.name}) ? 0.5 : 1.0)
                                .padding(.vertical, 3)
                                .contextMenu {
                                    Button{openURL(URL(string: "https://lichess.org/study/\(study.id)")!)} label: {
                                        Label("Visit Study on Lichess.com", systemImage: "safari")
                                    }
                                }
//                                Spacer()
                                Toggle("", isOn: binding(for: study.id))
                                    .toggleStyle(WhitePieceToggleStyle())
                            }
                            .if(database.gametrees.contains(where: {$0.name == study.name})) { view in
                                view._untagged()
                            }
                        }
                        .listRowBackground(colorScheme == .dark ? [28,28,30].getColor():Color.white)
                    }
                    .refreshable() {
                        do {
                            studyList = try await getUserLichessStudies()
                            sortStudies()
                        } catch {
                            print(error)
                        }
                    }
                    .listStyle(.inset)
                    
                    Spacer()
                    Button(action: {
                        Task {
                            await addUserLichessStudies()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add selected Studies")
                    }
                    .foregroundColor(.green)
                    .padding()
                } else {
                    List(selection: $exampleSelection) {
                        ForEach(ExamplePGN.list, id: \.self) { listItem in
                            VStack(alignment: .leading) {
                                Text(listItem.name)
                                Text("created by " + listItem.creator)
                                    .font(Font.caption2)
                            }
                            .opacity(database.gametrees.contains(where: {$0.name == listItem.name}) ? 0.5 : 1.0)
                            .padding(.vertical, 3)
                            .contextMenu {
                                Button{openURL(URL(string: listItem.url)!)} label: {
                                    Label("Visit Study on Lichess.com", systemImage: "safari")
                                }
                            }
                            .if(database.gametrees.contains(where: {$0.name == listItem.name})) { view in
                                view._untagged()
                            }
                        }
                        .listRowBackground(colorScheme == .dark ? [28,28,30].getColor():Color.white)
                    }
                    .listStyle(.inset)
                    .listRowSeparator(.hidden)
                    
                    Button(action: {
                        addExamples()
                    }) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add selected Studies")
                    }
                    .foregroundColor(.green)
                    .padding()
                    
                }
                Picker("awdawd", selection: $examplePicker) {
                    Text("Custom PGN").tag(0)
                    if settings.playerRating != nil {
                        Text("Lichess").tag(1)
                    }
                    Text("Examples").tag(2)
                }.pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom)
                
            }
            .onAppear() {
                Task {
                    do {
                        studyList = try await getUserLichessStudies()
                        sortStudies()
                    } catch {
                        print(error)
                    }
                }
            }
            .navigationTitle(Text("Add Study"))
            .environment(\.editMode, $editMode)
            .toolbar {
                Button(action:{
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
            .alert("Enter the Lichess Study URL", isPresented: $showingLichessAlert) {
                TextField("Lichess Study URL", text: $lichessURL)
                Button("Import") {
                    Task {
                        do {
                            self.pgnString = try await getPGNFromLichess(url: lichessURL)
                        } catch let localError {
                            switch localError {
                            case LichessPGNError.urlInvalid:
                                importProblemText = "The provided URL is not valid."
                            case LichessPGNError.noLichessUrl:
                                importProblemText = "The provided URL is not a lichess.com URL."
                            case LichessPGNError.badResponse:
                                importProblemText = "A problem occured while downloading. Please try again later."
                            case LichessPGNError.createdUrlInvalid:
                                importProblemText = "A problem occured while downloading. Please try again later."
                            default:
                                break
                            }
                            showingImportProblem = true
                            lichessURL = ""
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Paste in the exact lichess.com url of the study you want to import.")
            }
        }
    }
    
    func addStudy() {
        if pgnString.isEmpty && nameString.isEmpty {
            nameError = true
            pgnError = true
        } else if nameString.isEmpty {
            nameError = true
        } else if pgnString.isEmpty {
            pgnError = true
        } else if database.gametrees.contains(where: {$0.name == nameString}) {
            duplicateError = true
            nameError = true
        } else {
            Task {
                let result = await database.addNewGameTree(name: nameString, pgnString: pgnString, userColor: selectedPieceColor)
                await MainActor.run {
                    if result {
                        self.dismiss()
                    } else {
                        pgnError = true
                    }
                }
            }
        }
    }
    
    func addExamples() {
        isLoading = true
        if exampleSelection.isEmpty { return }
        Task {
            for example in exampleSelection {
                if let pgnString = example.pgnString {
                    _ = await self.database.addNewGameTree(name: example.name, pgnString: pgnString, userColor: example.userColor)
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
        self.dismiss()
    }
    
    private func binding(for key: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.colorDict[key] ?? true },
            set: { self.colorDict[key] = $0 }
        )
    }
    
    func getPGNFromLichess(url urlString: String) async throws -> String {
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
    
    func getPGNFromLichess(id: String) async throws -> String {
        guard let apiURL = URL(string: "https://lichess.org/api/study/\(id).pgn") else { throw LichessPGNError.createdUrlInvalid}
        guard let (data, _) = try? await URLSession.shared.data(from: apiURL) else { throw LichessPGNError.badResponse}
        return try String(data: data, encoding: .utf8) ?? {throw LichessPGNError.badResponse}()
    }
    
    enum LichessPGNError: String, Error {
        case urlInvalid, noLichessUrl, badResponse, createdUrlInvalid, decodingError, noUserName
    }
    
    func getUserLichessStudies() async throws -> [LichessStudyMetaData] {
        guard let name = settings.lichessName else { throw LichessPGNError.noUserName}
        var studyList: [LichessStudyMetaData] = []
        let urlString = "https://lichess.org/api/study/by/\(name)"
        guard let url = URL(string: urlString) else { throw LichessPGNError.urlInvalid }
        
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { throw LichessPGNError.badResponse}
        
        guard let ndjsonString = String(data: data, encoding: .utf8) else { throw LichessPGNError.decodingError}
        
        let lines = ndjsonString.components(separatedBy: .newlines)
        
        let decoder = JSONDecoder()
        
        for line in lines {
            // Skip empty lines
            guard !line.isEmpty else {
                continue
            }

            // Decode each line as a separate JSON object
            let data = Data(line.utf8)
            let study = try decoder.decode(LichessStudyMetaData.self, from: data)
            studyList.append(study)
        }
        
        return studyList
    }
    
    func addUserLichessStudies() async {
        isLoading = true
        for study in lichessSelection {
            do {
                let pgnString = try await getPGNFromLichess(id: study.id)
                var userColor = PieceColor.white
                if let colorIsWhite = colorDict[study.id] {
                    userColor = colorIsWhite ? .white : .black
                }
                let _ = await database.addNewGameTree(name: study.name, pgnString: pgnString, userColor: userColor)
            } catch { }
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    func dateStringFromTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
//        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
    func sortStudies() {
        studyList.sort(by: {
            if databaseContainsStudy($0) && !databaseContainsStudy($1) {
                return false
            } else if databaseContainsStudy($1) && !databaseContainsStudy($0) {
                return true
            } else {
                return $0.updatedAt > $1.updatedAt
            }
        })
        self.colorDict = [:]
        for study in studyList {
            self.colorDict[study.id] = true
        }
    }
    
    func databaseContainsStudy(_ study: LichessStudyMetaData) -> Bool {
        database.gametrees.contains(where: {$0.name == study.name})
    }
}

struct LichessStudyMetaData: Codable, Hashable {
    let id: String
    let name: String
    let createdAt: Int
    let updatedAt: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AddStudyView_Previews: PreviewProvider {
    static var previews: some View {
        AddStudyView(database: DataBase(), settings: Settings(), isLoading: .constant(false), pgnString: .constant(""))
    }
}
