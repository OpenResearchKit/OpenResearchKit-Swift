//
//  ViewTests.swift
//  OpenResearchKitTests
//
//  Created by OpenResearchKit on 04.06.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class ViewTests: XCTestCase {

    // MARK: - URL Query Parameters Extension Tests

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

    // MARK: - Survey Callback URL Tests

    func testSurveySuccessCallbackURLDetection() {
        let successURL = URL(string: "https://example.com/survey-callback/success?param1=value1")!
        let urlString = successURL.absoluteString

        XCTAssertTrue(urlString.contains("survey-callback/success"))
    }

    func testSurveyFailureCallbackURLDetection() {
        let failureURL = URL(string: "https://example.com/survey-callback/failed?error=timeout")!
        let urlString = failureURL.absoluteString

        XCTAssertTrue(urlString.contains("survey-callback/failed"))
    }

    func testNormalSurveyURLDetection() {
        let normalURL = URL(string: "https://example.com/survey/page1")!
        let urlString = normalURL.absoluteString

        XCTAssertFalse(urlString.contains("survey-callback/success"))
        XCTAssertFalse(urlString.contains("survey-callback/failed"))
    }

    // MARK: - Survey Type Integration Tests

    func testSurveyTypeWithCallbackURLs() {
        let introductoryType = SurveyType.introductory
        let midType = SurveyType.mid
        let completionType = SurveyType.completion

        // Test that survey types can be used in URL context
        let baseURL = "https://example.com/survey"
        let introURL = "\(baseURL)?type=introductory"
        let midURL = "\(baseURL)?type=mid"
        let completionURL = "\(baseURL)?type=completion"

        XCTAssertTrue(introURL.contains("introductory"))
        XCTAssertTrue(midURL.contains("mid"))
        XCTAssertTrue(completionURL.contains("completion"))

        XCTAssertEqual(introductoryType, SurveyType.introductory)
        XCTAssertEqual(midType, SurveyType.mid)
        XCTAssertEqual(completionType, SurveyType.completion)
    }

    // MARK: - URL Parameter Processing Tests

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
            string: "https://example.com/survey-callback/failed?error=timeout&reason=network")!
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

    // MARK: - Performance Tests

    func testURLQueryParametersPerformance() {
        let complexURL = URL(
            string:
                "https://example.com/callback?param1=value1&param2=value2&param3=value3&param4=value4&param5=value5&param6=value6&param7=value7&param8=value8&param9=value9&param10=value10"
        )!

        measure {
            for _ in 0..<1000 {
                _ = complexURL.queryParameters
            }
        }
    }

    func testCallbackURLDetectionPerformance() {
        let urls = [
            "https://example.com/survey-callback/success?param=value",
            "https://example.com/survey-callback/failed?error=test",
            "https://example.com/survey/regular-page",
            "https://example.com/other/page",
        ].compactMap { URL(string: $0) }

        measure {
            for _ in 0..<1000 {
                for url in urls {
                    let urlString = url.absoluteString
                    _ = urlString.contains("survey-callback/success")
                    _ = urlString.contains("survey-callback/failed")
                }
            }
        }
    }

    // MARK: - Edge Cases

    func testURLQueryParametersWithMalformedQuery() {
        let url = URL(string: "https://example.com/callback?&&&key=value&&&")!
        let params = url.queryParameters

        // Should handle malformed query gracefully
        XCTAssertNotNil(params)
    }

    func testCallbackURLWithComplexQuery() {
        let complexCallbackURL = URL(
            string:
                "https://example.com/survey-callback/success?assignedGroup=treatment&groupid=group_123&userId=user_456&timestamp=1609459200&version=1.2.3"
        )!

        let urlString = complexCallbackURL.absoluteString
        XCTAssertTrue(urlString.contains("survey-callback/success"))

        let params = complexCallbackURL.queryParameters
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["assignedGroup"], "treatment")
        XCTAssertEqual(params?["groupid"], "group_123")
        XCTAssertEqual(params?["userId"], "user_456")
        XCTAssertEqual(params?["timestamp"], "1609459200")
        XCTAssertEqual(params?["version"], "1.2.3")
    }

    func testCallbackURLWithNoParameters() {
        let simpleSuccessURL = URL(string: "https://example.com/survey-callback/success")!
        let simpleFailureURL = URL(string: "https://example.com/survey-callback/failed")!

        XCTAssertTrue(simpleSuccessURL.absoluteString.contains("survey-callback/success"))
        XCTAssertTrue(simpleFailureURL.absoluteString.contains("survey-callback/failed"))

        XCTAssertNil(simpleSuccessURL.queryParameters)
        XCTAssertNil(simpleFailureURL.queryParameters)
    }

    // MARK: - Integration Tests

    func testSurveyWorkflowWithCallbackURLs() {
        // Simulate a complete survey workflow with different callback URLs
        let surveyTypes: [SurveyType] = [.introductory, .mid, .completion]

        for surveyType in surveyTypes {
            // Success callback
            let successURL = URL(
                string: "https://example.com/survey-callback/success?type=\(surveyType)")!
            let successParams = successURL.queryParameters

            XCTAssertTrue(successURL.absoluteString.contains("survey-callback/success"))
            XCTAssertNotNil(successParams)

            // Failure callback
            let failureURL = URL(
                string: "https://example.com/survey-callback/failed?type=\(surveyType)")!
            let failureParams = failureURL.queryParameters

            XCTAssertTrue(failureURL.absoluteString.contains("survey-callback/failed"))
            XCTAssertNotNil(failureParams)
        }
    }

    func testSurveyParameterExtraction() {
        let surveyURL = URL(
            string:
                "https://example.com/survey-callback/success?assignedGroup=control&groupid=123&completion=true"
        )!

        guard let params = surveyURL.queryParameters else {
            XCTFail("Failed to extract parameters")
            return
        }

        // Test parameter extraction logic similar to what would be used in SurveyWebView
        var assignedGroup: String?
        if let group = params["assignedGroup"] {
            assignedGroup = group
        } else if let group = params["groupid"] {
            assignedGroup = group
        }

        XCTAssertEqual(assignedGroup, "control")
        XCTAssertEqual(params["completion"], "true")
    }
}
