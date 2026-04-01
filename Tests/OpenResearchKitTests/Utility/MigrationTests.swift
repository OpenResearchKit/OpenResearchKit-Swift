//
//  MigrationTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 07.10.25.
//

import XCTest
@testable import OpenResearchKit

class DummyMigration: DataMigration {
    
    var id: String
    
    init(id: String) {
        self.id = id
    }
    
    func perform() async throws {
        
        print("Execute some kind of migration")
        
    }
    
}

class ThrowingMigration: DataMigration {
    
    var id: String
    
    init(id: String) {
        self.id = id
    }
    
    func perform() async throws {
        
        throw TestError.example
        
    }
    
    enum TestError: LocalizedError {
        case example
    }
    
}

class MigrationTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        
        OpenResearchKitMigrations.reset()
    }
    
    func testMigrationExecutes() async throws {
        
        OpenResearchKitMigrations.register([
            DummyMigration(id: "20250929T103000-dummy")
        ])
        
        try await OpenResearchKitMigrations.execute()
        
        let identifiers = UserDefaults.standard.stringArray(forKey: "org.openresearchkit.migrations.v1.executed")
        
        XCTAssertEqual(identifiers?.count, 1)
        XCTAssertEqual(identifiers, ["20250929T103000-dummy"])
        
    }
    
    func testMigrationsDontExecuteAfterThrowingMigration() async throws {
        
        OpenResearchKitMigrations.register([
            DummyMigration(id: "20250701T103000-dummy"),
            DummyMigration(id: "20250929T103000-dummy"),
            ThrowingMigration(id: "20250812T103000-dummy")
        ])
        
        do {
            
            try await OpenResearchKitMigrations.execute()
            
            XCTFail("If this is executed, the throwing migration was not executed and thus the test failed.")
            
        } catch {
            
            let identifiers = UserDefaults.standard.stringArray(forKey: "org.openresearchkit.migrations.v1.executed")
            
            XCTAssertEqual(identifiers?.count, 1)
            XCTAssertEqual(identifiers, ["20250701T103000-dummy"])
            
        }
        
    }
    
}

