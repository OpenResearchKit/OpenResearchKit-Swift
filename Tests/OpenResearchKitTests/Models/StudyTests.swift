//
//  StudyTests.swift
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

final class StudyTests: XCTestCase {
    
    // MARK: - Tests
    
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

    // MARK: - File Handling -
    
    func test_studyContainer_createsExpectedPath_andDirectory() throws {
        let studyID = "TestStudy-\(UUID().uuidString)"
        let study = Dummy.makeStudy(id: studyID)
        
        // Ensure clean state
        let expectedDir = try documentsDirectory()
            .appendingPathComponent("OpenResearchKit/Studies", isDirectory: true)
            .appendingPathComponent(studyID, isDirectory: true)
            .appendingPathComponent("working", isDirectory: true)
        removeItemIfExists(expectedDir)
        
        // Act
        let url = study.studyDirectory()
        
        // Assert: path correctness
        XCTAssertEqual(url, expectedDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        // Assert: it's a directory
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
    
    func test_studyContainer_isIdempotent() throws {
        let studyID = "Idempotent-\(UUID().uuidString)"
        let study = Dummy.makeStudy(id: studyID)
        
        let first = study.studyDirectory()
        let second = study.studyDirectory()
        
        XCTAssertEqual(first, second)
        
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
    
    func testStudyBuildsSurveyUrl() {
        
        let study = DataDonationStudy(
            studyIdentifier: "test",
            studyInformation: StudyInformation(
                title: "",
                subtitle: "",
                contactEmail: "test@example.com",
                image: nil,
                duration: 10,
            ),
            uploadConfiguration: .dummy,
            introductorySurveyURL: URL(string: "https://example.com/intro"),
            introSurveyCompletionHandler: nil
        )
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        
        study.additionalQueryItems = { _ in
            return [URLQueryItem(name: "version", value: "1.0")]
        }
        let other = study.surveyUrl(for: .introductory)
        
        XCTAssertTrue(other!.absoluteString.contains("version=1.0"))
        
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
    
    // MARK: - Test helpers
    
    private struct Dummy {
        static func makeStudy(
            id: String = UUID().uuidString
        ) -> Study {
            
            let info = StudyInformation(
                title: "Dummy",
                subtitle: "",
                contactEmail: "",
                image: nil,
                duration: 60 * 60
            )
            
            let uploadConfig = UploadConfiguration(
                fileSubmissionServer: URL(string: "https://example.com/upload")!,
                uploadFrequency: 3600,
                apiKey: "TEST_API_KEY"
            )
            
            return DataDonationStudy(
                studyIdentifier: id,
                studyInformation: info,
                uploadConfiguration: uploadConfig,
                introductorySurveyURL: nil,
                participationIsPossible: true,
                additionalQueryItems: { _ in [] },
                introSurveyCompletionHandler: nil
            )
        }
    }
    
    private func documentsDirectory() throws -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let url else { throw NSError(domain: "Test", code: 1) }
        return url
    }
    
    private func removeItemIfExists(_ url: URL) {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
    }
    
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
