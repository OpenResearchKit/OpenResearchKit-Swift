//
//  DataMigration.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 07.10.25.
//

protocol DataMigration {
    
    /// Unique identifier, e.g. "20250929T103000-rename-key"
    var id: String { get }
    
    func perform() async throws
    
}
