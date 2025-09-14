//
//  StudyKeyValueStore.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

typealias OpenResearchDefaults = [String: [String: Any]]

/// A key-value store wrapper around `UserDefaults` that manages
/// per-study persisted values in the shared app defaults.
final class StudyKeyValueStore {
    
    private static let key = "open_research_kit"
    
    private let defaults: UserDefaults
    private let studyIdentifier: String
    
    /// Creates a key-value store for a specific study.
    /// - Parameters:
    ///   - studyIdentifier: The identifier of the study whose values should be stored.
    ///   - appGroup: Optional app group identifier if the data should be shared.
    init(studyIdentifier: String, appGroup: String?) {
        self.studyIdentifier = studyIdentifier
        if let appGroup {
            self.defaults = UserDefaults(suiteName: appGroup)!
        } else {
            self.defaults = UserDefaults.standard
        }
    }
    
    /// Returns all stored values for this study.
    func values() -> [String: Any] {
        let studyValues = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        return studyValues[studyIdentifier] ?? [:]
    }
    
    func get<T>(_ key: String, type: T.Type) -> T? {
        return values()[key] as? T
    }
    
    /// Replaces all stored values for this study.
    func saveValues(_ values: [String: Any]) {
        var currentDefaults = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        currentDefaults[studyIdentifier] = values
        defaults.set(currentDefaults, forKey: Self.key)
    }
    
    func update(_ key: String, value: Any?) {
        self.updateValues { values in
            values[key] = value
        }
    }
    
    /// Reads the current values for this study, lets the closure update them,
    /// and then saves the updated values.
    func updateValues(_ update: (inout [String: Any]) -> Void) {
        var allDefaults = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        var studyDefaults = allDefaults[studyIdentifier] ?? [:]
        
        update(&studyDefaults)
        
        allDefaults[studyIdentifier] = studyDefaults
        defaults.set(allDefaults, forKey: Self.key)
    }
    
}
