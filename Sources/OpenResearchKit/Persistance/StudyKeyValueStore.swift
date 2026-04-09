//
//  StudyKeyValueStore.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

typealias OpenResearchDefaults = [String: [String: Any]]

/// A lightweight wrapper around `UserDefaults` that persists **per-study** values
/// under a shared top-level dictionary (`"open_research_kit"`).
///
/// Each study’s values are stored at key path:
/// `open_research_kit[studyIdentifier] -> [String: Any]`.
///
/// ### Design goals
/// - Keep multiple studies’ values separated.
/// - Offer ergonomic read/update helpers without exposing the whole defaults store.
/// - Remain compatible with `App Group` containers (via `suiteName`).
///
/// ### Threading
/// This type does **not** perform internal synchronization. If you update from multiple
/// threads concurrently, coordinate access externally (e.g., via an actor or serial queue).
public final class StudyKeyValueStore {
    
    /// Top-level key in `UserDefaults` that holds all study dictionaries.
    private static let key = "open_research_kit"
    
    private let defaults: UserDefaults
    private let studyIdentifier: String
    
    /// Creates a key-value store scoped to a specific study.
    /// - Parameters:
    ///   - studyIdentifier: Identifier used to namespace this study’s values.
    ///   - appGroup: Optional App Group identifier; when provided, a shared
    ///               `UserDefaults(suiteName:)` is used. Otherwise `.standard`.
    init(studyIdentifier: String, appGroup: String?) {
        self.studyIdentifier = studyIdentifier
        if let appGroup {
            self.defaults = UserDefaults(suiteName: appGroup)!
        } else {
            self.defaults = UserDefaults.standard
        }
    }
    
    /// Returns **all** stored values for this study.
    ///
    /// If no values exist, an empty dictionary is returned.
    /// - Returns: `[String: Any]` for this study.
    func values() -> [String: Any] {
        let studyValues = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        return studyValues[studyIdentifier] ?? [:]
    }
    
    /// Reads a **typed** value for a given key from this study’s values.
    ///
    /// - Important: This performs a simple cast (`as? T`). Make sure the stored
    ///              type matches `T` (e.g., `Date`, `String`, `Int`, `Bool`, etc.).
    /// - Parameters:
    ///   - key: The value key inside the study dictionary.
    ///   - type: The expected value type (for readability at call sites).
    /// - Returns: The typed value if present and castable, otherwise `nil`.
    public func get<T>(_ key: String, type: T.Type) -> T? {
        return values()[key] as? T
    }
    
    /// Replaces **all** stored values for this study.
    ///
    /// - Parameter values: The entire dictionary to persist for this study.
    func replaceValues(_ values: [String: Any]) {
        var currentDefaults = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        currentDefaults[studyIdentifier] = values
        defaults.set(currentDefaults, forKey: Self.key)
    }
    
    /// Sets or removes a **single** key in this study’s values and persists the change.
    ///
    /// - Parameters:
    ///   - key: The key to update.
    ///   - value: New value. Pass `nil` to **remove** the key from the study’s dictionary.
    public func update(_ key: String, value: Any?) {
        self.updateValues { values in
            values[key] = value // assigning nil removes the key
        }
    }
    
    /// Loads current values, lets the caller mutate them, then saves the result.
    ///
    /// Use this to perform atomic “read-modify-write” operations without
    /// manually fetching and resaving the full dictionary.
    ///
    /// - Parameter update: An inout closure that receives the current values
    ///                     (or an empty dict) to modify in place.
    func updateValues(_ update: (inout [String: Any]) -> Void) {
        var allDefaults = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        var studyDefaults = allDefaults[studyIdentifier] ?? [:]
        
        update(&studyDefaults)
        
        allDefaults[studyIdentifier] = studyDefaults
        defaults.set(allDefaults, forKey: Self.key)
    }
    
    /// Deletes **all** stored values for this study.
    ///
    /// This removes the entire entry at:
    /// `open_research_kit[studyIdentifier]`.
    func deleteAllValues() {
        var allDefaults = defaults.dictionary(forKey: Self.key) as? OpenResearchDefaults ?? [:]
        allDefaults.removeValue(forKey: studyIdentifier)
        defaults.set(allDefaults, forKey: Self.key)
    }
}
