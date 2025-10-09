//
//  OpenResearchKitMigrations.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 29.09.25.
//

import Foundation


public enum OpenResearchKitMigrations {
    
    private static var registry: [DataMigration] = []
    private static let storeKey = "org.openresearchkit.migrations.v1.executed"
    private static let defaults = UserDefaults.standard
    
    /// Registers multiple data migration in the registry.
    /// - Note: If a migration with the same name already exists, the new migration is being ignored and not added to the registry.
    static func register(_ migrations: [DataMigration]) {
        migrations.forEach { register($0) }
    }
    
    /// Registers a data migration in the registry.
    /// - Note: If a migration with the same name already exists, the new migration is being ignored and not added to the registry.
    private static func register(_ migration: DataMigration) {
        guard registry.contains(where: { $0.id == migration.id }) == false else { return }
        registry.append(migration)
    }
    
    /// Run all migrations that haven't been executed yet, sorted by identifier.
    /// - Note: If a migration fails, the subsequent migrations are not being executed.
    public static func execute() async throws {
        var executed = loadExecuted()
        
        // Sort by id (lexicographic is chronological if the ids start with timestamps)
        let pending = registry
            .sorted { $0.id < $1.id }
            .filter { executed.contains($0.id) == false }
        
        for migration in pending {
            do {
                try await migration.perform()
                executed.insert(migration.id)
                saveExecuted(executed)
            } catch {
                // Stop at first failure to keep things simple and safe.
                throw error
            }
        }
    }
    
    // MARK: - Simple persistence
    
    private static func loadExecuted() -> Set<String> {
        let ids = defaults.stringArray(forKey: storeKey) ?? []
        return Set(ids)
    }
    
    private static func saveExecuted(_ set: Set<String>) {
        defaults.set(Array(set), forKey: storeKey)
    }
    
    internal static func reset() {
        defaults.removeObject(forKey: storeKey)
    }
    
}
