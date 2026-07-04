//
//  EngineWrapper.swift
//  OpeningsMastermind
//

import Foundation
import ChessKitEngine

/// Wraps ChessKitEngine's async Engine, exposing only the subset needed by this app.
///
/// Handles the async lifecycle complexity (startup handshake, response streaming)
/// so callers can use simple synchronous-style calls.
///
/// **Lifecycle:** ChessKitEngine runs Stockfish in-process via `_main()`, which is
/// not re-entrant — once it exits (on `quit`) it cannot be cleanly restarted, and
/// overlapping start/stop pairs corrupt the process-wide stdout/stdin redirection
/// it relies on. So the engine is started exactly **once** and kept alive for the
/// app's lifetime. "Turning the engine off" pauses the search via `pauseAnalysis()`
/// rather than tearing the engine down.
@MainActor
final class EngineWrapper {

    /// Process-wide singleton — the **only** `EngineWrapper` that should ever exist.
    ///
    /// Stockfish runs once per process and can't be restarted in-process, and
    /// ChessKitEngine `dup2`s the *process-wide* stdin/stdout. So a second started
    /// `Engine` corrupts those shared fds: two `UCIEngine::loop` threads race
    /// `getline` on the same stdin and splice command bytes together, producing a
    /// malformed FEN that crashes Stockfish with a `count<Pt>(c) == 1` /
    /// `piece_on` assertion. Owning the engine per–view model (a `lazy var`) was
    /// unsafe because `ExploreViewModel.init()` starts the engine, and SwiftUI
    /// constructs throwaway view models (e.g. `ContentView.init` runs on every
    /// re-init, `@StateObject` keeps only the first) — each leaving a leaked,
    /// never-torn-down Stockfish behind. Funnelling everyone through `shared`
    /// guarantees exactly one Stockfish regardless of how many VMs come and go.
    static let shared = EngineWrapper()

    /// Called on MainActor whenever the engine produces a response.
    var responseHandler: ((EngineResponse) -> Void)?

    private let engine = Engine(type: .stockfish)
    private var listenerTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?

    /// FEN stored when analyzePosition is called before the engine is ready.
    private var pendingFEN: String?

    /// Guards against starting Stockfish more than once (see type-level note).
    private var didStart = false

    /// Private so the only instance is ``shared`` — see its note for why a second
    /// started engine corrupts the process-wide stdin/stdout.
    private nonisolated init() {}

    // MARK: - Public interface

    /// Starts the engine and begins listening for responses. Idempotent — calling
    /// it again after the first start is a no-op, so callers can safely invoke it
    /// whenever the engine is (re-)enabled.
    func start() async {
        guard !didStart else { return }
        // SwiftUI previews run in a sandboxed agent process where spawning
        // Stockfish — which dup2s the process-wide stdin/stdout and loads a
        // 79 MB NNUE — crashes the preview. Never start the engine there.
        guard !ProcessInfo.isRunningInPreviews else { return }
        didStart = true
        await engine.start(coreCount: 6)
        startListening()
    }

    /// Halts the current search but leaves the engine running, so analysis can be
    /// resumed later without re-initializing Stockfish. Used when the user turns
    /// the engine off.
    func pauseAnalysis() {
        let previous = analysisTask
        previous?.cancel()
        pendingFEN = nil
        // Chain the stop after any superseded sequence so it can't interleave on
        // the engine pipe with that sequence's still-pending writes (see
        // analyzePosition(fen:) for why writes must be serialized).
        analysisTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            await engine.send(command: .stop)
        }
    }

    /// Requests Stockfish analysis of the given FEN.
    /// Safe to call before the engine is fully ready — the request will be
    /// queued and executed once the engine reports readyok.
    ///
    /// Each call supersedes the previous one, but the new command sequence does
    /// **not** start writing until the previous task has fully finished (`await
    /// previous?.value`). This matters because `Engine.send` is not
    /// cancellation-aware and `EngineMessenger.sendCommand` writes to the engine
    /// pipe without synchronizing against other writers — so two overlapping
    /// `stop`/`position`/`go` sequences (e.g. the several rapid `analyzePosition`
    /// calls fired at launch) could byte-interleave into a corrupt command line,
    /// crashing Stockfish with a bad-FEN assertion. Serializing the sequences and
    /// bailing out early when superseded keeps exactly one sequence on the pipe.
    func analyzePosition(fen: String) {
        let previous = analysisTask
        previous?.cancel()
        analysisTask = Task { [weak self] in
            // Wait for any superseded sequence to finish writing before we begin,
            // so command bytes never interleave on the unsynchronized engine pipe.
            await previous?.value
            guard let self, !Task.isCancelled else { return }
            guard await engine.isRunning else {
                if !Task.isCancelled { pendingFEN = fen }
                return
            }
            guard !Task.isCancelled else { return }
            pendingFEN = nil
            await engine.send(command: .stop)
            await engine.send(command: .position(.fen(fen)))
            await engine.send(command: .go(depth: 20))
        }
    }

    // MARK: - Private

    private func startListening() {
        let engine = self.engine
        listenerTask = Task { [weak self] in
            guard let stream = await engine.responseStream else { return }
            for await response in stream {
                guard let self else { break }
                // Engine is fully ready — run any deferred analysis.
                if response == .readyok, let fen = pendingFEN {
                    pendingFEN = nil
                    analyzePosition(fen: fen)
                }
                responseHandler?(response)
            }
        }
    }
}
