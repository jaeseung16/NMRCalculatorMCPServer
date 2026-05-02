//
//  NMRTools.swift
//  NMRCalculator
//
//  Created by Jae Seung Lee on 4/28/26.
//  Copyright © 2026 Jae-Seung Lee. All rights reserved.
//

import Foundation
import MCP

enum NMRTools {

    // MARK: - Tool Definitions

    static var definitions: [Tool] {
        [
            Tool(
                name: "calculate_larmor_frequency",
                description: "Calculate the Larmor frequency of a nucleus at a given magnetic field strength (ω = γ × B₀).",
                inputSchema: schema(
                    properties: [
                        "nucleus": prop("string", "Nucleus identifier, e.g. \"1H\", \"13C\", \"31P\""),
                        "magnetic_field": prop("number", "Magnetic field strength in Tesla")
                    ],
                    required: ["nucleus", "magnetic_field"]
                )
            ),
            Tool(
                name: "calculate_magnetic_field",
                description: "Calculate the magnetic field required to observe a nucleus at a given Larmor frequency (B₀ = ω / γ).",
                inputSchema: schema(
                    properties: [
                        "nucleus": prop("string", "Nucleus identifier, e.g. \"1H\", \"13C\", \"31P\""),
                        "larmor_frequency": prop("number", "Larmor frequency in MHz")
                    ],
                    required: ["nucleus", "larmor_frequency"]
                )
            ),
            Tool(
                name: "get_nucleus_info",
                description: "Get properties of an NMR-active nucleus: gyromagnetic ratio, nuclear spin, and natural abundance.",
                inputSchema: schema(
                    properties: ["nucleus": prop("string", "Nucleus identifier, e.g. \"1H\", \"13C\", \"31P\"")],
                    required: ["nucleus"]
                )
            ),
            Tool(
                name: "list_nuclei",
                description: "List all NMR-active nuclei in the database with their identifiers and gyromagnetic ratios.",
                inputSchema: .object(["type": "object", "properties": .object([:])])
            ),
            Tool(
                name: "calculate_ernst_angle",
                description: "Calculate the Ernst angle — the optimal flip angle for maximum SNR in a repetitively pulsed experiment (θ = arccos(exp(−TR/T₁))).",
                inputSchema: schema(
                    properties: [
                        "repetition_time": prop("number", "Repetition time TR in seconds"),
                        "t1": prop("number", "Longitudinal relaxation time T₁ in seconds")
                    ],
                    required: ["repetition_time", "t1"]
                )
            ),
            Tool(
                name: "calculate_pulse_amplitude",
                description: "Calculate the RF amplitude needed to achieve a flip angle in a given pulse duration (A = (θ/360°) / τ).",
                inputSchema: schema(
                    properties: [
                        "duration": prop("number", "Pulse duration in microseconds"),
                        "flip_angle": prop("number", "Desired flip angle in degrees")
                    ],
                    required: ["duration", "flip_angle"]
                )
            ),
            Tool(
                name: "calculate_pulse_duration",
                description: "Calculate the pulse duration needed to achieve a flip angle at a given RF amplitude (τ = (θ/360°) / A).",
                inputSchema: schema(
                    properties: [
                        "flip_angle": prop("number", "Desired flip angle in degrees"),
                        "amplitude": prop("number", "RF amplitude in Hz")
                    ],
                    required: ["flip_angle", "amplitude"]
                )
            ),
        ]
    }

    // MARK: - Handler

    @MainActor
    static func handle(_ params: CallTool.Parameters) throws -> CallTool.Result {
        switch params.name {
        case "calculate_larmor_frequency": return try larmorFrequency(params.arguments)
        case "calculate_magnetic_field":   return try magneticField(params.arguments)
        case "get_nucleus_info":           return try nucleusInfo(params.arguments)
        case "list_nuclei":                return listNuclei()
        case "calculate_ernst_angle":      return try ernstAngle(params.arguments)
        case "calculate_pulse_amplitude":  return try pulseAmplitude(params.arguments)
        case "calculate_pulse_duration":   return try pulseDuration(params.arguments)
        default:
            throw MCPError.methodNotFound("Unknown tool: \(params.name)")
        }
    }

    // MARK: - Tool Implementations

    @MainActor
    private static func larmorFrequency(_ args: [String: Value]?) throws -> CallTool.Result {
        let id = try requireString(args, key: "nucleus")
        let field = try requireDouble(args, key: "magnetic_field")
        let nucleus = try findNucleus(id)
        let freq = nucleus.γ * field
        return text("The Larmor frequency of \(nucleus.nameNucleus) (\(nucleus.identifier)) at \(field) T is \(String(format: "%.4f", freq)) MHz.")
    }

    @MainActor
    private static func magneticField(_ args: [String: Value]?) throws -> CallTool.Result {
        let id = try requireString(args, key: "nucleus")
        let freq = try requireDouble(args, key: "larmor_frequency")
        let nucleus = try findNucleus(id)
        guard nucleus.γ != 0 else {
            throw MCPError.invalidParams("Gyromagnetic ratio is zero for '\(id)'")
        }
        let field = freq / nucleus.γ
        return text("A Larmor frequency of \(freq) MHz for \(nucleus.nameNucleus) (\(nucleus.identifier)) requires \(String(format: "%.4f", field)) T.")
    }

    @MainActor
    private static func nucleusInfo(_ args: [String: Value]?) throws -> CallTool.Result {
        let id = try requireString(args, key: "nucleus")
        let n = try findNucleus(id)
        return text("""
            Nucleus: \(n.nameNucleus) (\(n.identifier))
            Symbol: \(n.symbolNucleus)-\(n.atomicWeight)
            Nuclear spin: \(n.nuclearSpin)
            Gyromagnetic ratio (γ): \(String(format: "%.6f", n.γ)) MHz/T
            Natural abundance: \(n.naturalAbundance)%
            """)
    }

    @MainActor
    private static func listNuclei() -> CallTool.Result {
        let lines = NMRPeriodicTable.shared.nuclei.map {
            "\($0.identifier) (\($0.nameNucleus)): γ = \(String(format: "%.4f", $0.γ)) MHz/T"
        }
        return text(lines.joined(separator: "\n"))
    }

    private static func ernstAngle(_ args: [String: Value]?) throws -> CallTool.Result {
        let tr = try requireDouble(args, key: "repetition_time")
        let t1 = try requireDouble(args, key: "t1")
        guard t1 > 0 else { throw MCPError.invalidParams("'t1' must be greater than 0") }
        let angle = acos(exp(-tr / t1)) * 180.0 / .pi
        return text("Ernst angle for TR = \(tr) s, T₁ = \(t1) s: \(String(format: "%.2f", angle))°")
    }

    private static func pulseAmplitude(_ args: [String: Value]?) throws -> CallTool.Result {
        let duration = try requireDouble(args, key: "duration")
        let flipAngle = try requireDouble(args, key: "flip_angle")
        guard duration > 0 else { throw MCPError.invalidParams("'duration' must be greater than 0") }
        let amplitude = (flipAngle / 360.0) / (duration / 1_000_000)
        return text("RF amplitude for a \(flipAngle)° pulse of \(duration) μs: \(String(format: "%.2f", amplitude)) Hz")
    }

    private static func pulseDuration(_ args: [String: Value]?) throws -> CallTool.Result {
        let flipAngle = try requireDouble(args, key: "flip_angle")
        let amplitude = try requireDouble(args, key: "amplitude")
        guard amplitude > 0 else { throw MCPError.invalidParams("'amplitude' must be greater than 0") }
        let durationμs = (flipAngle / 360.0) / amplitude * 1_000_000
        return text("Pulse duration for a \(flipAngle)° flip at \(amplitude) Hz: \(String(format: "%.2f", durationμs)) μs")
    }

    // MARK: - Helpers

    @MainActor
    private static func findNucleus(_ id: String) throws -> NMRNucleus {
        let table = NMRPeriodicTable.shared
        if let idx = table.nucleiDictionary[id] { return table.nuclei[idx] }
        if let n = table.nucleiById[id] { return n }
        throw MCPError.invalidParams("Unknown nucleus '\(id)'. Call list_nuclei to see available identifiers.")
    }

    private static func requireString(_ args: [String: Value]?, key: String) throws -> String {
        guard let val = args?[key], let s = String(val) else {
            throw MCPError.invalidParams("Missing or invalid '\(key)' (expected a string)")
        }
        return s
    }

    private static func requireDouble(_ args: [String: Value]?, key: String) throws -> Double {
        guard let val = args?[key], let d = Double(val) else {
            throw MCPError.invalidParams("Missing or invalid '\(key)' (expected a number)")
        }
        return d
    }

    private static func text(_ string: String) -> CallTool.Result {
        CallTool.Result(content: [.text(text: string, annotations: nil, _meta: nil)])
    }

    private static func prop(_ type: String, _ description: String) -> Value {
        .object(["type": .string(type), "description": .string(description)])
    }

    private static func schema(properties: [String: Value], required: [String]) -> Value {
        .object([
            "type": "object",
            "properties": .object(properties),
            "required": .array(required.map { .string($0) })
        ])
    }
}
