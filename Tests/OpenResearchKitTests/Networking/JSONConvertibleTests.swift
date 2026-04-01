//
//  JSONConvertibleTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class JSONConvertibleTests: XCTestCase {
    
    func testJSONConvertibleStringConformance() {
        let value: JSONConvertible = "test string"
        XCTAssertTrue(value is String)
        XCTAssertEqual(value as? String, "test string")
    }
    
    func testJSONConvertibleIntConformance() {
        let value: JSONConvertible = 42
        XCTAssertTrue(value is Int)
        XCTAssertEqual(value as? Int, 42)
    }
    
    func testJSONConvertibleDoubleConformance() {
        let value: JSONConvertible = 3.14159
        XCTAssertTrue(value is Double)
        XCTAssertEqual(value as? Double, 3.14159)
    }
    
    func testJSONConvertibleBoolConformance() {
        let trueValue: JSONConvertible = true
        let falseValue: JSONConvertible = false
        
        XCTAssertTrue(trueValue is Bool)
        XCTAssertTrue(falseValue is Bool)
        XCTAssertEqual(trueValue as? Bool, true)
        XCTAssertEqual(falseValue as? Bool, false)
    }
    
    func testJSONConvertibleNSNumberConformance() {
        let value: JSONConvertible = NSNumber(value: 123)
        XCTAssertTrue(value is NSNumber)
        XCTAssertEqual((value as? NSNumber)?.intValue, 123)
    }
    
    func testJSONConvertibleNSStringConformance() {
        let value: JSONConvertible = NSString(string: "test")
        XCTAssertTrue(value is NSString)
        XCTAssertEqual(value as? NSString, "test")
    }
    
    func testJSONConvertibleArrayConformance() {
        let array: [JSONConvertible] = ["string", 42, true]
        let value: JSONConvertible = array
        
        XCTAssertTrue(value is [JSONConvertible])
        let convertedArray = value as? [JSONConvertible]
        XCTAssertNotNil(convertedArray)
        XCTAssertEqual(convertedArray?.count, 3)
    }
    
    func testJSONConvertibleDictionaryConformance() {
        let dict: [String: JSONConvertible] = [
            "string": "value",
            "number": 42,
            "bool": true,
        ]
        let value: JSONConvertible = dict
        
        XCTAssertTrue(value is [String: JSONConvertible])
        let convertedDict = value as? [String: JSONConvertible]
        XCTAssertNotNil(convertedDict)
        XCTAssertEqual(convertedDict?.count, 3)
    }
    
    func testJSONConvertibleTypes() {
        let string: JSONConvertible = "test"
        let int: JSONConvertible = 42
        let double: JSONConvertible = 3.14
        let bool: JSONConvertible = true
        
        XCTAssertTrue(string is String)
        XCTAssertTrue(int is Int)
        XCTAssertTrue(double is Double)
        XCTAssertTrue(bool is Bool)
    }
    
}
