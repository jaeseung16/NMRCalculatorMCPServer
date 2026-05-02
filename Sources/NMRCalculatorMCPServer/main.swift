//
//  main.swift
//  NMRCalculatorMCPServer
//
//  Created by Jae Seung Lee on 4/28/26.
//  Copyright © 2026 Jae-Seung Lee. All rights reserved.
//

import Foundation
import MCP

await MainActor.run { _ = NMRPeriodicTable.shared }

let server = Server(
    name: "nmr-calculator",
    version: "1.0.0",
    capabilities: Server.Capabilities(tools: .init())
)

await server.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: NMRTools.definitions)
}

await server.withMethodHandler(CallTool.self) { params in
    try await NMRTools.handle(params)
}

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()
