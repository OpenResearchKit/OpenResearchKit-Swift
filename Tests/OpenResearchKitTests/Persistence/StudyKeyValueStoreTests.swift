//
//  StudyKeyValueStoreTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import XCTest
@testable import OpenResearchKit

final class StudyKeyValueStoreTests: XCTestCase {

    private struct CodableTestValue: Codable, Equatable {
        let id: UUID
        let name: String
        let createdAt: Date
        let count: Int
    }
    
    private var suiteName: String!
    private var defaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Unique suite so tests don't interfere with each other or app defaults
        suiteName = "test.openresearchkit.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        // Ensure a clean slate for this suite
        defaults.removePersistentDomain(forName: suiteName)
    }
    
    override func tearDown() {
        // Clean up suite after each test
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }
    
    func testInitialValuesAreEmpty() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        XCTAssertTrue(store.values().isEmpty)
    }
    
    func testSaveAndReadRoundtrip() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        let now = Date()
        store.replaceValues([
            "lastUploadDate": now,
            "count": 3,
            "flag": true,
            "name": "Alice"
        ])
        
        let values = store.values()
        XCTAssertEqual(values["count"] as? Int, 3)
        XCTAssertEqual(values["flag"] as? Bool, true)
        XCTAssertEqual(values["name"] as? String, "Alice")
        XCTAssertEqual((values["lastUploadDate"] as! Date).timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.01)
    }
    
    func testUpdateValuesMergesChanges() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        store.replaceValues(["count": 1, "name": "Start"])
        
        store.updateValues { dict in
            dict["count"] = (dict["count"] as? Int ?? 0) + 1
            dict["added"] = "ok"
        }
        
        let values = store.values()
        XCTAssertEqual(values["count"] as? Int, 2)
        XCTAssertEqual(values["added"] as? String, "ok")
        XCTAssertEqual(values["name"] as? String, "Start") // unchanged key remains
    }
    
    func testTypedGet() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        store.replaceValues(["count": 7, "name": "Bob", "flag": false])
        
        XCTAssertEqual(store.get("count", type: Int.self), 7)
        XCTAssertEqual(store.get("name", type: String.self), "Bob")
        XCTAssertEqual(store.get("flag", type: Bool.self), false)
        XCTAssertNil(store.get("missing", type: String.self))
        XCTAssertNil(store.get("count", type: String.self)) // wrong type returns nil
    }
    
    func testUpdateSingleKeyAndRemove() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        store.replaceValues(["a": 1, "b": 2])
        
        // set/replace
        store.update("b", value: 42)
        XCTAssertEqual(store.get("b", type: Int.self), 42)
        
        // remove
        store.update("a", value: nil)
        XCTAssertNil(store.get("a", type: Int.self))
        XCTAssertEqual(store.values().keys.sorted(), ["b"])
    }

    func testCodableRoundtrip() throws {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        let value = CodableTestValue(
            id: UUID(),
            name: "Alice",
            createdAt: Date(timeIntervalSince1970: 1_746_188_400),
            count: 3
        )

        try store.updateCodable("codable", value: value)

        let restored = try store.getCodable("codable", type: CodableTestValue.self)
        XCTAssertEqual(restored, value)
        XCTAssertNotNil(store.get("codable", type: Data.self))
    }

    func testCodableArrayRoundtrip() throws {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        let values = [
            CodableTestValue(
                id: UUID(),
                name: "Alice",
                createdAt: Date(timeIntervalSince1970: 1_746_188_400),
                count: 3
            ),
            CodableTestValue(
                id: UUID(),
                name: "Bob",
                createdAt: Date(timeIntervalSince1970: 1_746_192_000),
                count: 7
            )
        ]

        try store.updateCodable("codableArray", value: values)

        let restored = try store.getCodable("codableArray", type: [CodableTestValue].self)
        XCTAssertEqual(restored, values)
    }

    func testMissingCodableKeyReturnsNil() throws {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)

        let restored = try store.getCodable("missing", type: CodableTestValue.self)

        XCTAssertNil(restored)
    }

    func testNilCodableUpdateRemovesKey() throws {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        let value = CodableTestValue(
            id: UUID(),
            name: "Alice",
            createdAt: Date(timeIntervalSince1970: 1_746_188_400),
            count: 3
        )

        try store.updateCodable("codable", value: value)
        XCTAssertNotNil(store.get("codable", type: Data.self))

        try store.updateCodable("codable", value: Optional<CodableTestValue>.none)

        XCTAssertNil(store.get("codable", type: Data.self))
        XCTAssertNil(try store.getCodable("codable", type: CodableTestValue.self))
    }

    func testCodableGetThrowsWhenStoredValueIsNotData() throws {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        store.update("codable", value: "not-data")

        XCTAssertThrowsError(try store.getCodable("codable", type: CodableTestValue.self)) { error in
            XCTAssertEqual(
                error as? StudyKeyValueStoreError,
                .storedValueIsNotData(key: "codable")
            )
        }
    }

    func testCodableGetThrowsDecoderErrorForCorruptData() throws {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        store.update("codable", value: Data("not-json".utf8))

        XCTAssertThrowsError(try store.getCodable("codable", type: CodableTestValue.self)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testIsolationBetweenStudies() {
        let a = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        let b = StudyKeyValueStore(studyIdentifier: "study-B", appGroup: suiteName)
        
        a.replaceValues(["onlyA": true])
        b.replaceValues(["onlyB": true])
        
        XCTAssertEqual(a.get("onlyA", type: Bool.self), true)
        XCTAssertNil(a.get("onlyB", type: Bool.self))
        
        XCTAssertEqual(b.get("onlyB", type: Bool.self), true)
        XCTAssertNil(b.get("onlyA", type: Bool.self))
    }
    
    func testDeleteAllValuesRemovesStudyDictionary() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        store.replaceValues(["a": 1, "b": 2])
        XCTAssertFalse(store.values().isEmpty)
        
        store.deleteAllValues()
        
        XCTAssertTrue(store.values().isEmpty, "All values for the study should be removed")
        // Ensure the top-level still exists (could still hold other studies)
        let top = defaults.dictionary(forKey: "open_research_kit") ?? [:]
        XCTAssertFalse(top.keys.contains("study-A"))
    }
    
    func testDeleteAllValuesIsIdempotent() {
        let store = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        // Delete when nothing exists
        store.deleteAllValues()
        XCTAssertTrue(store.values().isEmpty)
        
        // Create then delete twice
        store.replaceValues(["x": 42])
        XCTAssertEqual(store.get("x", type: Int.self), 42)
        
        store.deleteAllValues()
        XCTAssertNil(store.get("x", type: Int.self))
        
        // Second delete should be a no-op and not crash
        store.deleteAllValues()
        XCTAssertTrue(store.values().isEmpty)
    }
    
    func testDeleteDoesNotAffectOtherStudies() {
        let a = StudyKeyValueStore(studyIdentifier: "study-A", appGroup: suiteName)
        let b = StudyKeyValueStore(studyIdentifier: "study-B", appGroup: suiteName)
        
        a.replaceValues(["onlyA": true])
        b.replaceValues(["onlyB": true])
        
        a.deleteAllValues()
        
        XCTAssertTrue(a.values().isEmpty)
        XCTAssertEqual(b.get("onlyB", type: Bool.self), true, "Other studies must remain intact")
    }
    
}
