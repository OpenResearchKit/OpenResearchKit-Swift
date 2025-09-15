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
        let study = createLongTermStudy()
        
        XCTAssertEqual(study.studyInformation.title, "Test Study")
        XCTAssertEqual(study.studyInformation.subtitle, "Test Subtitle")
        XCTAssertEqual(study.duration, 10)
        XCTAssertEqual(study.studyInformation.contactEmail, "test@example.com")
        XCTAssertEqual(study.uploadConfiguration.apiKey, "test")
        XCTAssertEqual(study.uploadConfiguration.uploadFrequency, 60)
    }
    
    func testEmptyAdditionalQueryItems() {
        let study = createLongTermStudy()
        
        study.additionalQueryItems = { _ in [] }
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertFalse(url!.absoluteString.contains("&="))
    }
    
    func testStudyBuildsCompletionSurveyUrl() {
        let study = createLongTermStudy()
        
        let url = study.surveyUrl(for: .completion)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/conclusion"))
    }
    
    func testStudyBuildsMidSurveyUrl() {
        
        let study = createLongTermMidStudy()
        
        let url = study.surveyUrl(for: .mid)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/mid"))
    }
    
    func testStudyAdditionalQueryItems() {
        let study = createLongTermStudy()
        
        study.additionalQueryItems = { _ in
            return [URLQueryItem(name: "version", value: "1.0")]
        }
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("version=1.0"))
    }
    
    func testStudyUserIdentifierGeneration() {
        let study = createLongTermStudy()
        
        let userIdentifier = study.userIdentifier
        
        XCTAssertFalse(userIdentifier.isEmpty)
    }
    
    func testStudyJSONFileHandling() {
        let study = createLongTermStudy()
        
        try? study.reset()
        study.saveUserConsentHasBeenGiven(completion: {})
        
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
        let study = createLongTermStudy()
        
        try? study.reset()
        
        XCTAssertNil(study.lastSuccessfulUploadDate)
        
        let testDate = Date()
        study.updateUploadDate(newDate: testDate)
        
        XCTAssertNotNil(study.lastSuccessfulUploadDate)
        XCTAssertEqual(
            study.lastSuccessfulUploadDate!.timeIntervalSince1970, testDate.timeIntervalSince1970,
            accuracy: 1.0)
    }
    
    func testFinishedConclusionSurveyOrNotNeeded() {
        
        let study1 = createLongTermStudy(concludingSurvey: nil)
        
        // Concluding survey not needed
        XCTAssertTrue(study1.finishedConclusionSurveyOrNotNeeded)
        
        let study2 = createLongTermStudy(concludingSurvey: URL(string: "https://example.org")!)
        
        // Concluding survey needed but not finished
        XCTAssertFalse(study2.finishedConclusionSurveyOrNotNeeded)
        
        study2.hasCompletedTerminationSurvey = true
        
        // Concluding survey needed and now finished
        XCTAssertTrue(study2.finishedConclusionSurveyOrNotNeeded)
        
    }
    
    func testIsActiveLongTermWithConclusionSurveyRegularFlow() {
        
        let dateGenerator = TimeTraveler()
        let study = createLongTermStudy()
        study.dateGenerator = dateGenerator
        
        XCTAssertFalse(study.isActive)
        
        study.saveUserConsentHasBeenGiven(completion: {})
        
        XCTAssertTrue(study.isActive)
        
        dateGenerator.travel(by: 20)
        
        study.hasCompletedTerminationSurvey = true
        
        XCTAssertFalse(study.isActive)
        
    }
    
    func testIsActiveLongTermWithConclusionEarlyTerminate() {
        
        let dateGenerator = TimeTraveler()
        let study = createLongTermStudy(duration: 10)
        study.dateGenerator = dateGenerator
        
        XCTAssertFalse(study.isActive)
        
        study.saveUserConsentHasBeenGiven(completion: {})
        
        dateGenerator.travel(by: 5)
        XCTAssertTrue(study.isActive)
        
        dateGenerator.travel(by: 20)
        
        // Should be true as the user still needs to do the termination survey
        XCTAssertTrue(study.isActive)
        
        study.terminateParticipationImmediately()
        
        XCTAssertFalse(study.isActive)
        
    }
    
    // MARK: - Test helpers
    
    private let uploadConfiguration = UploadConfiguration(
        fileSubmissionServer: URL(string: "https://example.com/upload")!,
        uploadFrequency: 60,
        apiKey: "test"
    )
    
    private func createLongTermMidStudy(
        introductorySurvey: URL? = URL(string: "https://example.com/intro")!,
        concludingSurvey: URL? = URL(string: "https://example.com/conclusion")!,
        duration: TimeInterval = 10
    ) -> LongTermWithMidSurveyStudy {
        
        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: "test",
            studyInformation: .init(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurvey!,
            midStudySurvey: .init(showAfter: 50 * 60, url: URL(string: "https://example.com/mid")!),
            concludingSurveyURL: concludingSurvey!,
            introSurveyCompletionHandler: nil
        )
        
        try? study.reset()
        
        return study
        
    }
    
    private func createLongTermStudy(
        introductorySurvey: URL? = URL(string: "https://example.com/intro")!,
        concludingSurvey: URL? = URL(string: "https://example.com/conclusion")!,
        duration: TimeInterval = 10
    ) -> LongTermStudy {
        
        let study = LongTermStudy(
            studyIdentifier: UUID().uuidString,
            studyInformation: .init(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurvey,
            concludingSurveyURL: concludingSurvey,
            introSurveyCompletionHandler: nil
        )
        
        try? study.reset()
        
        return study
        
    }
    
}
