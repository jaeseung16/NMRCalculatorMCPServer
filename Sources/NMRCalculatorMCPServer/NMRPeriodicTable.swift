//
//  NMRNucleiTable.swift
//  NMRCalculator
//
//  Created by Jae Seung Lee on 8/19/18.
//  Copyright © 2018 Jae-Seung Lee. All rights reserved.
//

import Foundation

@MainActor
class NMRPeriodicTable {
    // MARK: - Properties
    static let shared = NMRPeriodicTable()
    let proton = NMRNucleus()
    var nuclei = [NMRNucleus]()
    var nucleiDictionary = [String: Int]()
    var nucleiById = [String: NMRNucleus]()
    
    // MARK: - Methods
    private init() {
        guard let nucleusTable = readtable() else {
            return
        }
        
        for k in 0..<(nucleusTable.count - 1) {
            let nucleus = NMRNucleus(string: nucleusTable[k])
            nuclei.append(nucleus)
            nucleiDictionary[nucleus.identifier] = k
            nucleiById[nucleus.id] = nucleus
        }
    }
    
    private func readtable() -> [String]? {
        NMRFreqTableData.content.components(separatedBy: .newlines)
    }
}
