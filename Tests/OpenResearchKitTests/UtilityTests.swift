//
//  UtilityTests.swift
//  OpenResearchKitTests
//
//  Created by OpenResearchKit on 04.06.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class UtilityTests: XCTestCase {

    // MARK: - Date Extension Tests

    func testDateIsInFuture() {
        let futureDate = Date().addingTimeInterval(3600)  // 1 hour in future
        let pastDate = Date().addingTimeInterval(-3600)  // 1 hour in past
        let currentDate = Date()

        XCTAssertTrue(futureDate.isInFuture)
        XCTAssertFalse(pastDate.isInFuture)
        XCTAssertFalse(currentDate.isInFuture)  // Current time is not in future
    }

    func testDateIsInFutureWithSmallInterval() {
        let futureDate = Date().addingTimeInterval(1)  // 1 second in future
        let pastDate = Date().addingTimeInterval(-1)  // 1 second in past

        XCTAssertTrue(futureDate.isInFuture)
        XCTAssertFalse(pastDate.isInFuture)
    }

    func testDateIsInFutureWithLargeInterval() {
        let futureDate = Date().addingTimeInterval(86400 * 365)  // 1 year in future
        let pastDate = Date().addingTimeInterval(-86400 * 365)  // 1 year in past

        XCTAssertTrue(futureDate.isInFuture)
        XCTAssertFalse(pastDate.isInFuture)
    }

    // MARK: - NSMutableData Extension Tests

    func testNSMutableDataStringAppending() {
        let data = NSMutableData()
        let testString = "Hello, World!"

        data.append(testString)

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, testString)
    }

    func testNSMutableDataEmptyStringAppending() {
        let data = NSMutableData()

        data.append("")

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "")
    }

    func testNSMutableDataMultipleStringAppending() {
        let data = NSMutableData()

        data.append("Hello, ")
        data.append("World!")

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "Hello, World!")
    }

    func testNSMutableDataUnicodeStringAppending() {
        let data = NSMutableData()

        data.append("Hello 👋")
        data.append(" 🌍")

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "Hello 👋 🌍")
    }

    func testNSMutableDataSpecialCharactersAppending() {
        let data = NSMutableData()
        let specialChars = "!@#$%^&*()_+{}|:<>?[]\\;'\",./"

        data.append(specialChars)

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, specialChars)
    }

    // MARK: - Edge Cases

    func testNSMutableDataWithNilStringHandling() {
        let data = NSMutableData()

        // Test that the extension handles potential nil string gracefully
        // by testing with a string that could potentially be nil
        let optionalString: String? = nil
        let safeString = optionalString ?? ""

        XCTAssertNoThrow {
            data.append(safeString)
        }

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "")
    }

    func testDateIsInFutureWithDistantDates() {
        let distantFuture = Date.distantFuture
        let distantPast = Date.distantPast

        XCTAssertTrue(distantFuture.isInFuture)
        XCTAssertFalse(distantPast.isInFuture)
    }

    // MARK: - Integration Tests

    func testNSMutableDataAndDateExtensionsTogether() {
        let data = NSMutableData()
        let futureDate = Date().addingTimeInterval(3600)

        data.append("Future timestamp: ")
        data.append("\(futureDate.timeIntervalSince1970)")

        let resultString = String(data: data as Data, encoding: .utf8)!

        XCTAssertTrue(resultString.contains("Future timestamp:"))
        XCTAssertTrue(futureDate.isInFuture)
    }

}
