//
//  Stockfish.swift
//  OpeningsMastermind
//
//  Created by Christian Gleißner on 30.05.23.
//

import Foundation
import ChessKitEngine
import ChessKit

class EngineClass: ObservableObject {
    public static let `default` = EngineClass()
    
    private let engine = Engine(type: .stockfish)
    
    private init() {
        self.engine.start(coreCount: 6)
        engine.send(command: .setoption(id: "Hash", value: "128"))
    }
    
    deinit {
        self.engine.stop()
    }
    
    @Published var evaluation: Double? = nil
    @Published var mateInXMoves: Int? = nil
    
    func start() async {
        await waitUntilReady()
//        engine.send(command: .setoption(id: "UCI_AnalyseMode", value: "true"))
//        engine.send(command: .setoption(id: "Use NNUE", value: "false"))
//        engine.loggingEnabled = true
    }
    
    func stop() {
        engine.send(command: .stop)
        evaluation = nil
        mateInXMoves = nil
    }
    
    func waitUntilReady() async {
        for _ in 0...50 {
            if engine.isRunning {
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
    
    func search(position: Position, moveColor: PieceColor) async {
        self.engine.send(command: .stop)
        await waitUntilReady()
        let fen = FenSerialization.default.serialize(position: position)
        self.engine.send(command: .position(.fen(fen)))
        self.engine.send(command: .go(depth: 18))
        self.engine.receiveResponse = { response in
            DispatchQueue.main.async {
                switch response {
                case let .info(info):
                    if let score = info.score?.cp {
                        self.mateInXMoves = nil
                        if moveColor == .white {
                            self.evaluation = score / 100.0
                        } else {
                            self.evaluation = -score / 100.0
                        }                        }
                    if let mateInXMoves = info.score?.mate {
                        if moveColor == .white {
                            if mateInXMoves == 0 {
                                self.evaluation = -50
                            } else {
                                self.evaluation = 10 * Double(mateInXMoves)
                            }
                            self.mateInXMoves = mateInXMoves
                        } else {
                            if mateInXMoves == 0 {
                                self.evaluation = 50
                            } else {
                                self.evaluation = -10 * Double(mateInXMoves)
                            }
                            self.mateInXMoves = -mateInXMoves
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    func analyze(positions: [Position], moveColor: PieceColor, index: Int, evaluationsInput: [Double], completion: @escaping (_ evaluations: [Double]) -> Void) async {
        if index >= positions.count {
            completion(evaluationsInput)
        }
        let position = positions[index]
        self.engine.send(command: .stop)
        await waitUntilReady()
        let fen = FenSerialization.default.serialize(position: position)
        self.engine.send(command: .position(.fen(fen)))
        self.engine.send(command: .go(depth: 18))
        self.engine.receiveResponse = { response in
            switch response {
            case let .info(info):
                if let score = info.score?.cp {
                    self.mateInXMoves = nil
                    if moveColor == .white {
                        self.evaluation = score / 100.0
                    } else {
                        self.evaluation = -score / 100.0
                    }                        }
                if let mateInXMoves = info.score?.mate {
                    if moveColor == .white {
                        if mateInXMoves == 0 {
                            self.evaluation = -50
                        } else {
                            self.evaluation = 10 * Double(mateInXMoves)
                        }
                        self.mateInXMoves = mateInXMoves
                    } else {
                        if mateInXMoves == 0 {
                            self.evaluation = 50
                        } else {
                            self.evaluation = -10 * Double(mateInXMoves)
                        }
                        self.mateInXMoves = -mateInXMoves
                    }
                }
            case .bestmove(move: _, ponder: _):
                let evaluationsOutput: [Double] = evaluationsInput + [self.evaluation ?? 0]
                Task {
                    await self.analyze(positions: positions, moveColor: moveColor == .white ? .black : .white, index: index + 1, evaluationsInput: evaluationsOutput) { evaluations in
                        completion(evaluations)
                    }
                }
            default:
                break
            }
        }
    }
}
