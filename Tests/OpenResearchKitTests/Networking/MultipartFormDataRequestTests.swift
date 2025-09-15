//
//  MultipartFormDataRequestTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class MultipartFormDataRequestTests: XCTestCase {
    
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
        let request = MultipartFormDataRequest(url: url)
        
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
        let request = MultipartFormDataRequest(url: url)
        
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
    
    func testMultipartFormDataURLRequest() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)
        
        request.addTextField(named: "test_field", value: "test_value")
        
        let urlRequest = request.asURLRequest()
        
        XCTAssertEqual(urlRequest.url, url)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNotNil(urlRequest.httpBody)
        XCTAssertTrue(
            urlRequest.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data")
            ?? false)
    }
    
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
    
}
