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

    // MARK: - Edge Cases

    func testMultipartFormDataWithSpecialCharacters() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)

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
        let request = MultipartFormDataRequest(url: url)

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
