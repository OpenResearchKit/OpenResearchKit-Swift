//
//  NetworkingTests.swift
//  OpenResearchKitTests
//
//  Created by OpenResearchKit on 04.06.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class NetworkingTests: XCTestCase {

    // MARK: - NSMutableData Extension Tests

    func testNSMutableDataStringAppending() {
        let data = NSMutableData()

        data.append("Hello, ")
        data.append("World!")

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "Hello, World!")
    }

    func testNSMutableDataEmptyStringAppending() {
        let data = NSMutableData()

        data.append("")

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "")
    }

    // MARK: - Integration Tests

    func testCompleteMultipartFormDataWorkflow() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)

        // Add various field types
        request.addTextField(named: "api_key", value: "test_key")
        request.addTextField(named: "user_id", value: "user123")

        let jsonData = try! JSONSerialization.data(withJSONObject: [
            "timestamp": Date().timeIntervalSince1970,
            "data": ["key1": "value1", "key2": "value2"],
        ])

        request.addDataField(
            named: "file",
            filename: "data.json",
            data: jsonData,
            mimeType: "application/json"
        )

        let urlRequest = request.asURLRequest()

        // Verify all components are present
        XCTAssertEqual(urlRequest.url, url)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNotNil(urlRequest.httpBody)

        let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type")!
        XCTAssertTrue(contentType.contains("multipart/form-data"))
        XCTAssertTrue(contentType.contains("boundary="))

        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("api_key"))
        XCTAssertTrue(bodyString.contains("test_key"))
        XCTAssertTrue(bodyString.contains("user_id"))
        XCTAssertTrue(bodyString.contains("user123"))
        XCTAssertTrue(bodyString.contains("data.json"))
        XCTAssertTrue(bodyString.contains("application/json"))
    }

    // MARK: - Edge Cases

    func testMultipartFormDataWithSpecialCharacters() {
        let url = URL(string: "https://example.com/upload")!
        var request = MultipartFormDataRequest(url: url)

        request.addTextField(
            named: "special_chars", value: "Hello! @#$%^&*()_+{}|:<>?[]\\;'\",./ 🌍")

        let urlRequest = request.asURLRequest()
        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!

        XCTAssertTrue(bodyString.contains("special_chars"))
        XCTAssertTrue(bodyString.contains("Hello!"))
        XCTAssertTrue(bodyString.contains("🌍"))
    }

    func testMultipartFormDataWithEmptyValues() {
        let url = URL(string: "https://example.com/upload")!
        var request = MultipartFormDataRequest(url: url)

        request.addTextField(named: "empty_field", value: "")
        request.addDataField(
            named: "empty_file", filename: "", data: Data(), mimeType: "text/plain")

        let urlRequest = request.asURLRequest()

        XCTAssertNotNil(urlRequest.httpBody)
        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("empty_field"))
        XCTAssertTrue(bodyString.contains("empty_file"))
    }
}
