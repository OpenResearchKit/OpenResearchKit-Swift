//
//  LongTermStudyTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 12.09.25.
//

import XCTest
@testable import OpenResearchKit

extension UploadConfiguration {
    
    static let dummy: UploadConfiguration = .init(
        fileSubmissionServer: URL(string: "https://example.org/upload")!,
        uploadFrequency: 60 * 60 * 24,
        apiKey: ""
    )
    
}

final class LongTermStudyTests: XCTestCase {
    
    // MARK: - Tests
    
    func testStudyInitialization() {
        let study = createTestStudy()
        
        XCTAssertEqual(study.studyInformation.title, "Test Study")
        XCTAssertEqual(study.studyInformation.subtitle, "Test Subtitle")
        XCTAssertEqual(study.duration, 18000)
        XCTAssertEqual(study.studyIdentifier, "test")
        XCTAssertEqual(study.studyInformation.contactEmail, "test@example.com")
        XCTAssertEqual(study.uploadConfiguration.apiKey, "test")
        XCTAssertEqual(study.uploadConfiguration.uploadFrequency, 60)
    }
    
    func testEmptyAdditionalQueryItems() {
        let study = createTestStudy()
        
        study.additionalQueryItems = { _ in [] }
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertFalse(url!.absoluteString.contains("&="))
    }
    
    func testStudyBuildsCompletionSurveyUrl() {
        let study = createTestStudy()
        
        let url = study.surveyUrl(for: .completion)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/conclusion"))
    }
    
    func testStudyBuildsMidSurveyUrl() {
        
        let midSurvey = MidStudySurvey(showAfter: 3600, url: URL(string: "https://example.com/mid")!)
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
    
    // MARK: - Test helpers
    
    private func createTestStudy(midStudySurvey: MidStudySurvey? = nil) -> LongTermStudy {
        
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
                    image: nil
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
                    image: nil
                ),
                uploadConfiguration: uploadConfiguration,
                duration: 60 * 60 * 5,
                introductorySurveyURL: URL(string: "https://example.com/intro")!,
                concludingSurveyURL: URL(string: "https://example.com/conclusion")!,
                introSurveyCompletionHandler: nil
            )
        }
    }
    
}
