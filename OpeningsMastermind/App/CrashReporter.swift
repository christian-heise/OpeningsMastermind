//
//  CrashReporter.swift
//  OpeningsMastermind
//

import Foundation
import MetricKit
import TelemetryDeck

/// Subscribes to MetricKit's on-device crash diagnostics and forwards a
/// summary to TelemetryDeck. MetricKit collects crashes via the OS itself
/// (no custom signal/exception handlers) and delivers a batched
/// `MXDiagnosticPayload` roughly once a day. It does not deliver diagnostics
/// while a debugger is attached or on Simulator.
final class CrashReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = CrashReporter()

    static func start() {
        MXMetricManager.shared.add(shared)
    }

    static func stop() {
        MXMetricManager.shared.remove(shared)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            for diagnostic in payload.crashDiagnostics ?? [] {
                let header = "Signal \(diagnostic.signal?.description ?? "?"), "
                    + "exception \(diagnostic.exceptionType?.description ?? "?")/\(diagnostic.exceptionCode?.description ?? "?"), "
                    + "reason: \(diagnostic.terminationReason ?? "unknown")\n"
                let stack = String(data: diagnostic.callStackTree.jsonRepresentation(), encoding: .utf8) ?? ""
                TelemetryDeck.errorOccurred(id: "uncaught-crash", category: .appState, message: String((header + stack).prefix(2000)))
            }
        }
    }
}
