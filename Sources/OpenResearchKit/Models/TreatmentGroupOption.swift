//
//  TreatmentGroupOption.swift
//  OpenResearchKit
//
//  Created by Codex on 10.03.26.
//

import Foundation

public struct TreatmentGroupOption: Identifiable, Hashable, Sendable {
    
    public let id: String
    public let displayName: String
    
    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
    
}
