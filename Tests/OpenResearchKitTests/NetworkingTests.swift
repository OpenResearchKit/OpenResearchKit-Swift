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

    // MARK: - MultipartFormDataRequest Tests

    func testMultipartFormDataRequestInitialization() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)

        XCTAssertEqual(request.url, url)
    }

    func testMultipartFormDataAddTextField() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)

        request.addTextField(named: "username", value: "testuser")
        request.addTextField(named: "email", value: "test@example.com")

        let urlRequest = request.asURLRequest()

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNotNil(urlRequest.httpBody)

        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("username"))
        XCTAssertTrue(bodyString.contains("testuser"))
        XCTAssertTrue(bodyString.contains("email"))
        XCTAssertTrue(bodyString.contains("test@example.com"))
    }

    func testMultipartFormDataAddDataField() {
        let url = URL(string: "https://example.com/upload")!
        var request = MultipartFormDataRequest(url: url)

        let testData = "test file content".data(using: .utf8)!
        request.addDataField(
            named: "file",
            filename: "test.txt",
            data: testData,
            mimeType: "text/plain"
        )

        let urlRequest = request.asURLRequest()

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNotNil(urlRequest.httpBody)

        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"file\""))
        XCTAssertTrue(bodyString.contains("filename=\"test.txt\""))
        XCTAssertTrue(bodyString.contains("Content-Type: text/plain"))
        XCTAssertTrue(bodyString.contains("test file content"))
    }

    func testMultipartFormDataMixedFields() {
        let url = URL(string: "https://example.com/upload")!
        var request = MultipartFormDataRequest(url: url)

        // Add text field
        request.addTextField(named: "api_key", value: "secret123")

        // Add data field
        let jsonData = try! JSONSerialization.data(withJSONObject: ["key": "value"])
        request.addDataField(
            named: "data",
            filename: "data.json",
            data: jsonData,
            mimeType: "application/json"
        )

        let urlRequest = request.asURLRequest()

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertTrue(
            urlRequest.value(forHTTPHeaderField: "Content-Type")?
                .contains("multipart/form-data; boundary=") ?? false
        )

        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("api_key"))
        XCTAssertTrue(bodyString.contains("secret123"))
        XCTAssertTrue(bodyString.contains("data.json"))
        XCTAssertTrue(bodyString.contains("application/json"))
    }

    func testMultipartFormDataBoundaryGeneration() {
        let url = URL(string: "https://example.com/upload")!
        let request1 = MultipartFormDataRequest(url: url)
        let request2 = MultipartFormDataRequest(url: url)

        let urlRequest1 = request1.asURLRequest()
        let urlRequest2 = request2.asURLRequest()

        let contentType1 = urlRequest1.value(forHTTPHeaderField: "Content-Type")!
        let contentType2 = urlRequest2.value(forHTTPHeaderField: "Content-Type")!

        // Boundaries should be different (UUID-based)
        XCTAssertNotEqual(contentType1, contentType2)
        XCTAssertTrue(contentType1.contains("multipart/form-data; boundary="))
        XCTAssertTrue(contentType2.contains("multipart/form-data; boundary="))
    }

    func testMultipartFormDataEmptyRequest() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)

        let urlRequest = request.asURLRequest()

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNotNil(urlRequest.httpBody)

        // Even empty request should have boundary markers
        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("--"))
    }

    // MARK: - JSONConvertible Protocol Tests

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

    func testNSMutableDataUnicodeStringAppending() {
        let data = NSMutableData()

        data.append("Hello 👋")
        data.append(" 🌍")

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, "Hello 👋 🌍")
    }

    // MARK: - URLSession Extension Tests

    func testURLSessionMultipartDataTaskCreation() {
        let url = URL(string: "https://httpbin.org/post")!
        let request = MultipartFormDataRequest(url: url)
        request.addTextField(named: "test", value: "value")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // This test just verifies the method exists and creates a task
            // We don't actually want to make a real network request in unit tests
        }

        XCTAssertNotNil(task)
        XCTAssertEqual(task.originalRequest?.url, url)
        XCTAssertEqual(task.originalRequest?.httpMethod, "POST")
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
