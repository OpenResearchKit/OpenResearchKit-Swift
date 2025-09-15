import Foundation
import XCTest

@testable import OpenResearchKit

final class OpenResearchKitOldTests: XCTestCase {

    // MARK: - URL Extension Tests

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

    func testAppendSingleQueryItem() {
        let url = URL(string: "https://example.org")!
        let resultUrl = url.appendingQueryItem(name: "param", value: "value")

        XCTAssertEqual(resultUrl.absoluteString, "https://example.org?param=value")
    }

    func testAppendQueryItemWithNilValue() {
        let url = URL(string: "https://example.org")!
        let resultUrl = url.appendingQueryItem(name: "param", value: nil)

        XCTAssertEqual(resultUrl.absoluteString, "https://example.org?param")
    }

    func testQueryParametersExtraction() {
        let url = URL(string: "https://example.org?param1=value1&param2=value2")!
        let params = url.queryParameters

        XCTAssertNotNil(params)
        XCTAssertEqual(params?["param1"], "value1")
        XCTAssertEqual(params?["param2"], "value2")
    }

    func testQueryParametersWithoutQuery() {
        let url = URL(string: "https://example.org")!
        let params = url.queryParameters

        XCTAssertNil(params)
    }

    // MARK: - SurveyType Tests

    func testSurveyTypeEnumValues() {
        XCTAssertEqual(SurveyType.introductory, SurveyType.introductory)
        XCTAssertEqual(SurveyType.mid, SurveyType.mid)
        XCTAssertEqual(SurveyType.completion, SurveyType.completion)
    }

    // MARK: - MidStudySurvey Tests

    func testMidStudySurveyInitialization() {
        let url = URL(string: "https://example.com/mid-survey")!
        let timeInterval: TimeInterval = 3600  // 1 hour

        let midSurvey = MidStudySurvey(showAfter: timeInterval, url: url)

        XCTAssertEqual(midSurvey.showAfter, timeInterval)
        XCTAssertEqual(midSurvey.url, url)
    }

    // MARK: - JSONConvertible Tests

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

    // MARK: - MultipartFormDataRequest Tests

    func testMultipartFormDataRequestInitialization() {
        let url = URL(string: "https://example.com/upload")!
        let request = MultipartFormDataRequest(url: url)

        XCTAssertEqual(request.url, url)
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

    // MARK: - Study Tests (Core functionality only)

    func testStudyInitialization() {
        let study = createTestStudy()

        XCTAssertEqual(study.studyInformation.title, "Test Study")
        XCTAssertEqual(study.studyInformation.subtitle, "Test Subtitle")
        XCTAssertEqual(study.studyInformation.duration, 10)
        XCTAssertEqual(study.studyIdentifier, "test")
        XCTAssertEqual(study.studyInformation.contactEmail, "test@example.com")
        XCTAssertEqual(study.uploadConfiguration.apiKey, "test")
        XCTAssertEqual(study.uploadConfiguration.uploadFrequency, 60)
    }

    func testStudyBuildsSurveyUrl() {
        let study = createTestStudy()

        let url = study.surveyUrl(for: .introductory)

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/intro"))
    }

    func testStudyBuildsCompletionSurveyUrl() {
        let study = createTestStudy()

        let url = study.surveyUrl(for: .completion)

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/conclusion"))
    }

    func testStudyBuildsMidSurveyUrl() {
        let midSurvey = MidStudySurvey(
            showAfter: 3600, url: URL(string: "https://example.com/mid")!)
        let study = createTestStudy(midStudySurvey: midSurvey)

        let url = study.surveyUrl(for: .mid)

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/mid"))
    }

    func testStudyAdditionalQueryItems() {
        let study = createTestStudy()

        study.additionalQueryItems = { _ in
            return [URLQueryItem(name: "version", value: "1.0")]
        }

        let url = study.surveyUrl(for: .introductory)

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("version=1.0"))
    }

    func testStudyUserIdentifierGeneration() {
        let study = createTestStudy()

        let userIdentifier = study.userIdentifier

        XCTAssertFalse(userIdentifier.isEmpty)
        XCTAssertTrue(userIdentifier.contains("test"))  // Contains study identifier
    }

    func testStudyJSONFileHandling() {
        let study = createTestStudy()
        
        try? study.reset()
        study.saveUserConsentHasBeenGiven(consentTimestamp: Date(), completion: {})

        let initialJSONFile = study.JSONFile
        XCTAssertTrue(initialJSONFile.isEmpty)

        let newObjects: [[String: JSONConvertible]] = [
            ["key1": "value1", "timestamp": 123_456_789],
            ["key2": "value2", "timestamp": 123_456_790],
        ]

        study.appendNewJSONObjects(newObjects: newObjects)

        let updatedJSONFile = study.JSONFile
        XCTAssertEqual(updatedJSONFile.count, 2)
    }

    func testStudyUploadDateHandling() {
        let study = createTestStudy()

        try? study.reset()
        
        XCTAssertNil(study.lastSuccessfulUploadDate)

        let testDate = Date()
        study.updateUploadDate(newDate: testDate)

        XCTAssertNotNil(study.lastSuccessfulUploadDate)
        XCTAssertEqual(
            study.lastSuccessfulUploadDate!.timeIntervalSince1970, testDate.timeIntervalSince1970,
            accuracy: 1.0)
    }

    // MARK: - Date Extension Tests

    func testDateIsInFuture() {
        let futureDate = Date().addingTimeInterval(3600)  // 1 hour in future
        let pastDate = Date().addingTimeInterval(-3600)  // 1 hour in past
        let currentDate = Date()

        XCTAssertTrue(futureDate.isInFuture)
        XCTAssertFalse(pastDate.isInFuture)
        XCTAssertFalse(currentDate.isInFuture)  // Current time is not in future
    }

    // MARK: - NSMutableData Extension Tests

    func testNSMutableDataStringAppending() {
        let data = NSMutableData()
        let testString = "Hello, World!"

        data.append(testString)

        let resultString = String(data: data as Data, encoding: .utf8)
        XCTAssertEqual(resultString, testString)
    }

    // MARK: - Edge Cases

    func testEmptyAdditionalQueryItems() {
        let study = createTestStudy()

        study.additionalQueryItems = { _ in [] }

        let url = study.surveyUrl(for: .introductory)

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertFalse(url!.absoluteString.contains("&="))
    }

    // MARK: - Helper Methods

    private func createTestStudy(midStudySurvey: MidStudySurvey? = nil) -> Study {
        
        let uploadConfiguration = UploadConfiguration(
            fileSubmissionServer: URL(string: "https://example.com/upload")!,
            uploadFrequency: 60,
            apiKey: "test"
        )
        
        if let midStudySurvey {
            return LongTermWithMidSurveyStudy(
                studyIdentifier: "test",
                studyInformation: .init(
                    title: "Test Study",
                    subtitle: "Test Subtitle",
                    contactEmail: "test@example.com",
                    image: nil,
                    duration: 10
                ),
                uploadConfiguration: uploadConfiguration,
                duration: 10,
                introductorySurveyURL: URL(string: "https://example.com/intro")!,
                midStudySurvey: midStudySurvey,
                concludingSurveyURL: URL(string: "https://example.com/conclusion")!,
                introSurveyCompletionHandler: nil
            )
        } else {
            return LongTermStudy(
                studyIdentifier: "test",
                studyInformation: .init(
                    title: "Test Study",
                    subtitle: "Test Subtitle",
                    contactEmail: "test@example.com",
                    image: nil,
                    duration: 10
                ),
                uploadConfiguration: uploadConfiguration,
                duration: 10,
                introductorySurveyURL: URL(string: "https://example.com/intro")!,
                concludingSurveyURL: URL(string: "https://example.com/conclusion")!,
                introSurveyCompletionHandler: nil
            )
        }
    }
}
