//
//  URLTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class URLTests: XCTestCase {
    
    func testURLQueryParametersExtraction() {
        let url = URL(string: "https://example.com/callback?success=true&userId=123&group=control")!
        let params = url.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["success"], "true")
        XCTAssertEqual(params?["userId"], "123")
        XCTAssertEqual(params?["group"], "control")
    }
    
    func testURLQueryParametersWithNoQuery() {
        let url = URL(string: "https://example.com/callback")!
        let params = url.queryParameters
        
        XCTAssertNil(params)
    }
    
    func testURLQueryParametersWithEmptyQuery() {
        let url = URL(string: "https://example.com/callback?")!
        let params = url.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertTrue(params?.isEmpty ?? false)
    }
    
    func testURLQueryParametersWithEncodedValues() {
        let url = URL(
            string: "https://example.com/callback?message=Hello%20World&email=test%40example.com")!
        let params = url.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["message"], "Hello World")
        XCTAssertEqual(params?["email"], "test@example.com")
    }
    
    func testURLQueryParametersWithDuplicateKeys() {
        // URLComponents typically takes the last value for duplicate keys
        let url = URL(string: "https://example.com/callback?key=value1&key=value2")!
        let params = url.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["key"], "value2")
    }
    
    func testURLQueryParametersWithEmptyValues() {
        let url = URL(string: "https://example.com/callback?key1=&key2=value&key3=")!
        let params = url.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["key1"], "")
        XCTAssertEqual(params?["key2"], "value")
        XCTAssertEqual(params?["key3"], "")
    }
    
    func testURLQueryParametersWithSpecialCharacters() {
        let url = URL(string: "https://example.com/callback?special=%21%40%23%24%25")!
        let params = url.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["special"], "!@#$%")
    }
    
    func testAppendSingleQueryItem() {
        
        let url = URL(string: "https://example.org")!
        let resultUrl = url.appendingQueryItem(name: "param", value: "value")
        
        XCTAssertEqual(resultUrl.absoluteString, "https://example.org?param=value")
        
    }
    
    func testAppendQueryItems() {
        
        let url = URL(string: "https://example.org?type=survey")!
        
        let additionalQueryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "version", value: "1"),
            URLQueryItem(name: "debug", value: "true"),
        ]
        
        XCTAssertEqual(
            url.appendingQueryItems(additionalQueryItems).absoluteString,
            "https://example.org?type=survey&language=en&version=1&debug=true"
        )
        
    }
    
    func testAppendQueryItemWithNilValue() {
        let url = URL(string: "https://example.org")!
        let resultUrl = url.appendingQueryItem(name: "param", value: nil)
        
        XCTAssertEqual(resultUrl.absoluteString, "https://example.org?param")
    }
    
    func testProcessingSuccessCallbackParameters() {
        let successURL = URL(
            string: "https://example.com/survey-callback/success?assignedGroup=control&userId=123")!
        let params = successURL.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["assignedGroup"], "control")
        XCTAssertEqual(params?["userId"], "123")
        
        // Simulate processing logic that would happen in a view
        if successURL.absoluteString.contains("survey-callback/success") {
            let success = true
            let assignedGroup = params?["assignedGroup"]
            let userId = params?["userId"]
            
            XCTAssertTrue(success)
            XCTAssertEqual(assignedGroup, "control")
            XCTAssertEqual(userId, "123")
        }
    }
    
    func testProcessingFailureCallbackParameters() {
        let failureURL = URL(
            string: "https://example.com/survey-callback/failed?error=timeout&reason=network"
        )!
        let params = failureURL.queryParameters
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["error"], "timeout")
        XCTAssertEqual(params?["reason"], "network")
        
        // Simulate processing logic that would happen in a view
        if failureURL.absoluteString.contains("survey-callback/failed") {
            let success = false
            let error = params?["error"]
            let reason = params?["reason"]
            
            XCTAssertFalse(success)
            XCTAssertEqual(error, "timeout")
            XCTAssertEqual(reason, "network")
        }
    }
    
}
