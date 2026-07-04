//
//  DataBase.swift
//  ChessOpeningTrainer
//
//  Created by Christian Gleißner on 22.04.23.
//

import Foundation
import os
import ChessKit
import TelemetryDeck

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpeningsMastermind", category: "DataBase")

let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
let startingGamePosition = FenSerialization.default.deserialize(fen: startingFEN)

class DataBase: ObservableObject, Codable {
    private var appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @Published var gametrees: [GameTree] = []
    
    @Published var sortSelection: SortingMethod = .manual
    @Published var sortingDirectionIncreasing: Bool = true
    
    @Published var isLoaded = false

    /// `true` once `load()` read a file but failed to decode it. While set, `save()`
    /// refuses to write so a failed load can't overwrite the (quarantined) real file
    /// with an empty database. Stays `false` on a normal first-launch missing file.
    private var loadDidFail = false

    /// A human readable description of the most recent import problem, or `nil`
    /// if the last import was fully successful. Set by `addNewGameTree`.
    @Published var lastImportMessage: String? = nil

    init() {
        Task {
            await load()
            await MainActor.run {
                self.isLoaded = true
            }
        }
    }
    
    init(gameTrees: [GameTree]) {
        self.gametrees = gameTrees
    }
    
    func save() {
        // A failed load leaves `gametrees` empty and the real file quarantined as
        // `gameTree.corrupted.json`. Writing now would persist an empty database over
        // the primary path and lose the user's studies for good — refuse instead.
        guard !loadDidFail else {
            logger.error("Refusing to save: database failed to load; preserving quarantined file")
            return
        }

        let filename = getDocumentsDirectory().appendingPathComponent("gameTree.json")

        do {
            // Encode on a dedicated large-stack thread — see `encodeOnLargeStackThread`.
            // The recursive `GameNode`/`MoveNode` encoders overflow the main thread's
            // small stack for very deep lines (~170+ plies), so encode there instead.
            let data = try Self.encodeOnLargeStackThread(self)
            try data.write(to: filename)
        } catch {
            logger.error("Failed to save database: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Encodes a `DataBase` on a dedicated `Thread` with a large stack — the mirror of
    /// `decodeOnLargeStackThread`.
    ///
    /// Two separate limits make the naive `JSONEncoder().encode` on the calling thread
    /// fail for deep lines, and this method addresses both:
    ///  1. **Stack.** `GameNode`/`MoveNode` `encode(to:)` recurse one frame per ply,
    ///     which overflows the small stack of the main thread (and of Swift-concurrency
    ///     cooperative threads). We give the encode a generous 64 MB stack.
    ///  2. **Nesting depth.** `JSONEncoder` delegates to `JSONSerialization`, which
    ///     hard-caps nesting at 512 levels (≈3 JSON containers per ply → ~170 plies),
    ///     throwing `Code=3840 "Too many nested arrays or dictionaries"` — a bigger
    ///     stack does *not* help. Binary property lists have no such cap, so we encode
    ///     with `PropertyListEncoder` instead. `decodeOnLargeStackThread` sniffs the
    ///     format and still reads legacy JSON `gameTree.json` files.
    ///
    /// Unlike the async decode, this blocks the caller on a semaphore: `save()` reads
    /// the *live*, main-actor-mutated graph, so the encode must not run concurrently
    /// with edits — parking the caller keeps it race-free while still borrowing the big
    /// stack. Not `private` so the deep-study stress test can exercise it directly.
    static func encodeOnLargeStackThread(_ database: DataBase) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Data, Error>!
        let thread = Thread {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            result = Result { try encoder.encode(database) }
            semaphore.signal()
        }
        thread.stackSize = 64 * 1024 * 1024
        thread.start()
        semaphore.wait()
        return try result.get()
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func load() async {
        let filename = getDocumentsDirectory().appendingPathComponent("gameTree.json")
        do {
            // Read and decode off the main thread so a large gameTree.json doesn't
            // block launch (Thread Performance Checker: "I/O on the main thread").
            // `load()` is a nonisolated async method, so this body already runs off
            // the main thread; the file read is fine here. The decode, however,
            // must NOT run on a Swift-concurrency cooperative thread: GameNode/
            // MoveNode `init(from:)` recurses one frame per ply, which overflows
            // those threads' small stacks for deep studies. Decode on a dedicated
            // Thread with a large stack instead. Only the published assignments
            // hop back to the main actor below.
            let data = try Data(contentsOf: filename)
            let database = try await Self.decodeOnLargeStackThread(from: data)
            await MainActor.run {
                self.appVersion = database.appVersion
                self.sortSelection = database.sortSelection
                self.sortingDirectionIncreasing = database.sortingDirectionIncreasing
                self.gametrees = database.gametrees
            }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            // Expected on first launch before any study has been saved.
        } catch {
            // The file exists but couldn't be decoded. `localizedDescription` is
            // useless for a `DecodingError` ("The data couldn't be read…"), so log the
            // full value — for a `DecodingError` it names the failing coding path, key
            // and expected type, which is what actually pinpoints the problem.
            logger.error("Failed to load database: \(String(describing: error), privacy: .public)")

            // Preserve the exact failing bytes for diagnosis and stop `save()` from
            // overwriting them with an empty database on the next background.
            Self.quarantineCorruptedDatabaseFile(at: filename)
            await MainActor.run { self.loadDidFail = true }

            if TelemetryManager.isInitialized {
                TelemetryDeck.signal("databaseLoadFailed",
                                     parameters: ["error": Self.diagnosticCategory(of: error)])
            }
        }
    }

    /// Moves an undecodable `gameTree.json` aside to `gameTree.corrupted.json` so its
    /// exact bytes survive (for pulling off the device to root-cause a decode failure)
    /// and a later `save()` can't clobber them. Mirrors `AppData`'s settings quarantine.
    private static func quarantineCorruptedDatabaseFile(at url: URL) {
        let quarantineURL = url.deletingPathExtension().appendingPathExtension("corrupted.json")
        do {
            _ = try FileManager.default.replaceItemAt(quarantineURL, withItemAt: url)
        } catch {
            logger.error("Failed to quarantine corrupted database file: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// A compact, PII-light label for the decode failure, suitable as a telemetry
    /// parameter. The full detail is in the local `os_log` line above.
    private static func diagnosticCategory(of error: Error) -> String {
        switch error {
        case let decoding as DecodingError:
            switch decoding {
            case .dataCorrupted:                 return "dataCorrupted"
            case .keyNotFound(let key, _):       return "keyNotFound:\(key.stringValue)"
            case .typeMismatch(let type, _):     return "typeMismatch:\(type)"
            case .valueNotFound(let type, _):    return "valueNotFound:\(type)"
            @unknown default:                    return "decodingUnknown"
            }
        case let cocoa as CocoaError:
            return "cocoa:\(cocoa.code.rawValue)"
        default:
            return "\(type(of: error))"
        }
    }
    
    /// Decodes a `DataBase` on a dedicated `Thread` with a large stack.
    /// The recursive `Codable` graph (one stack frame per ply) overflows the
    /// small stacks of Swift-concurrency cooperative threads — and, for very
    /// deep lines, even the main thread — so we give the decode a generous stack.
    ///
    /// New saves are binary property lists (see `encodeOnLargeStackThread`), but
    /// files written by older builds are JSON. We sniff the binary-plist magic
    /// (`bplist`) to pick the right decoder, so existing `gameTree.json` files keep
    /// loading; the next `save()` rewrites them as plist.
    static func decodeOnLargeStackThread(from data: Data) async throws -> DataBase {
        try await withCheckedThrowingContinuation { continuation in
            let thread = Thread {
                do {
                    let database: DataBase
                    if data.starts(with: Array("bplist".utf8)) {
                        database = try PropertyListDecoder().decode(DataBase.self, from: data)
                    } else {
                        database = try JSONDecoder().decode(DataBase.self, from: data)
                    }
                    continuation.resume(returning: database)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            thread.stackSize = 64 * 1024 * 1024
            thread.start()
        }
    }

    func addNewGameTree(_ gameTree: GameTree) {
        self.gametrees.append(gameTree)
        self.save()
    }
    
    func addNewGameTree(name: String, pgnString: String, userColor: PieceColor) async -> Bool {

        let newGameTree = GameTree(name: name, pgnString: pgnString, userColor: userColor)
        let warnings = PGNDecoder.default.lastWarnings

        if !newGameTree.rootNode.children.isEmpty {
            await MainActor.run {
                // Partial success: keep the tree but tell the user what was skipped.
                self.lastImportMessage = warnings.isEmpty ? nil : warnings.joined(separator: "\n")
                self.gametrees.append(newGameTree)
                self.save()
            }
            return true
        }
        else {
            await MainActor.run {
                self.lastImportMessage = warnings.first ?? "The PGN could not be read. Please check that it contains valid moves."
            }
            return false
        }
    }
    
    func removeGameTree(at offsets: IndexSet) {
        self.gametrees.remove(atOffsets: offsets)
        self.save()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        // Persist `sortSelection` as its stable string key, not via `SortingMethod`'s
        // own `Codable`: its raw value is a `LocalizedStringResource`, whose synthesized
        // codec is a dictionary. Old files (String raw value) stored a plain string, so
        // decoding them as a dictionary threw `typeMismatch` and — since this runs before
        // `gameTrees` — aborted the whole load, wiping every study on upgrade. A tolerant
        // string decode can't take the studies down with it: anything unexpected on disk
        // just falls back to `.manual`.
        if let key = try? container.decodeIfPresent(String.self, forKey: .sortSelection),
           let method = SortingMethod.allCases.first(where: { $0.rawValue.key == key }) {
            self.sortSelection = method
        } else {
            self.sortSelection = .manual
        }
        self.sortingDirectionIncreasing = try container.decodeIfPresent(Bool.self, forKey: .sortingDirectionIncreasing) ?? true
        
        if "0.7".isVersionGreater(than: self.appVersion) {
            let oldGameTrees = try container.decode([GameTreeOld].self, forKey: .gameTrees)
            logger.info("Successfully loaded \(oldGameTrees.count) old gametrees")

            if TelemetryManager.isInitialized {
                TelemetryDeck.signal("legacyGameTreeMigration", parameters: ["fromAppVersion": self.appVersion])
            }

            for oldTree in oldGameTrees {
                if oldTree.pgnString != "" {
                    self.gametrees.append(GameTree(fromOld: oldTree))
                }
            }
        } else {
            self.gametrees = try container.decode([GameTree].self, forKey: .gameTrees)
        }
        self.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(gametrees, forKey: .gameTrees)
        try container.encode(sortSelection.rawValue.key, forKey: .sortSelection)
        try container.encode(sortingDirectionIncreasing, forKey: .sortingDirectionIncreasing)
    }
    
    enum CodingKeys: String, CodingKey {
            case appVersion, gameTrees, sortSelection, sortingDirectionIncreasing
    }
}
