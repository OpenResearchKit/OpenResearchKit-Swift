//
//  DateTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class DateTests: XCTestCase {
    
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
    
    func testDateIsInFutureWithDistantDates() {
        let distantFuture = Date.distantFuture
        let distantPast = Date.distantPast
        
        XCTAssertTrue(distantFuture.isInFuture)
        XCTAssertFalse(distantPast.isInFuture)
    }
    
}
