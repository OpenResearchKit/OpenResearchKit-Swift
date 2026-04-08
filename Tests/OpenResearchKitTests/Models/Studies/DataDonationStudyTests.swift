//
//  DataDonationStudyTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import XCTest
@testable import OpenResearchKit

class DataDonationStudyTests: XCTestCase {
    
    func testStudyBuildsSurveyUrl() {
        
        let study = DataDonationStudy(
            studyIdentifier: "test",
            studyInformation: StudyInformation(
                title: "",
                subtitle: "",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: .dummy,
            introductorySurveyURL: URL(string: "https://example.com/intro")
        )
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        
        study.additionalQueryItems = { _ in
            return [URLQueryItem(name: "version", value: "1.0")]
        }
        let other = study.surveyUrl(for: .introductory)
        
        XCTAssertTrue(other!.absoluteString.contains("version=1.0"))
        
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
    
    // MARK: - State -
    
    func testStudyCompletedAfterSuccessfulIntroductorySurvey() {
        
        let study = Dummy.makeStudy()
        
        XCTAssertFalse(study.isActive)
        XCTAssertFalse(study.hasUserGivenConsent)
        
        let timeInSeconds = 2.0
        let expectation = XCTestExpectation(description: "Waiting shortly for the dismissal of the view")
        
        study.handleIntroductionSurveyResults(consented: true, parameters: [:], dismissView: {
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeInSeconds)
        
        XCTAssertTrue(study.isCompleted)
        XCTAssertFalse(study.isActive)
        
    }
    
    func testStudyNotCompletedAfterNotSuccessfulIntroductorySurvey() {
        
        let study = Dummy.makeStudy()
        
        XCTAssertFalse(study.isActive)
        XCTAssertFalse(study.hasUserGivenConsent)
        
        let timeInSeconds = 2.0
        let expectation = XCTestExpectation(description: "Waiting shortly for the dismissal of the view")
        
        study.handleIntroductionSurveyResults(consented: false, parameters: [:], dismissView: {
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: timeInSeconds)
        
        XCTAssertFalse(study.isCompleted)
        XCTAssertFalse(study.isActive)
        
    }
    
    // MARK: - Helpers -
    
    private struct Dummy {
        static func makeStudy(
            id: String = UUID().uuidString
        ) -> DataDonationStudy {
            
            let info = StudyInformation(
                title: "Dummy",
                subtitle: "",
                contactEmail: "",
                image: nil
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
                additionalQueryItems: { _ in [] }
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
    
}
