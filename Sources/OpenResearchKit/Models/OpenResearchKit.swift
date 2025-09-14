//
//  OpenResearchKit.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

typealias OpenResearchDefaults = [String: [String: Any]]

struct OpenResearchKit {
    
    static let Key = "open_research_kit"
    
    /// Returns the full defaults dictionary (all studies).
    static func researchKitDefaults(appGroup: String?) -> OpenResearchDefaults {
        
        getDefaults(appGroup: appGroup)
            .dictionary(forKey: Key) as? OpenResearchDefaults ?? [:]
        
    }
    
    /// Saves defaults for a single study, merging with existing values.
    static func saveStudyDefaults(defaults: [String: Any], appGroup: String?, studyIdentifier: String) {
        
        var currentDefaults = researchKitDefaults(appGroup: appGroup)
        currentDefaults[studyIdentifier] = defaults
        
        getDefaults(appGroup: appGroup).set(currentDefaults, forKey: Key)
        
    }
    
    /// Reads the defaults for a study, applies a closure to mutate them, and saves automatically.
    /// - Parameters:
    ///   - appGroup: Optional app group identifier for shared defaults.
    ///   - studyIdentifier: The study whose defaults should be modified.
    ///   - update: A closure that receives the current defaults (or empty dictionary) and returns the new defaults.
    static func updateStudyDefaults(
        appGroup: String?,
        studyIdentifier: String,
        update: (inout [String: Any]) -> Void
    ) {
        var allDefaults = researchKitDefaults(appGroup: appGroup)
        var studyDefaults = allDefaults[studyIdentifier] ?? [:]
        
        // Apply user-provided mutations
        update(&studyDefaults)
        
        // Save back
        allDefaults[studyIdentifier] = studyDefaults
        getDefaults(appGroup: appGroup).set(allDefaults, forKey: Key)
    }
    
    private static func getDefaults(appGroup: String?) -> UserDefaults {
        
        if let appGroup {
            return UserDefaults(suiteName: appGroup)!
        } else {
            return UserDefaults.standard
        }
        
    }
    
}
