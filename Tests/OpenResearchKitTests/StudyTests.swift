//
//  StudyTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 12.09.25.
//

import XCTest
@testable import OpenResearchKit

final class StudyTests: XCTestCase {
    
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
            
            return Study(
                studyIdentifier: id,
                studyInformation: info,
                uploadConfiguration: uploadConfig,
                introductorySurveyURL: nil,
                midStudySurvey: nil,
                concludingSurveyURL: nil,
                participationIsPossible: true,
                isDataDonationStudy: false,
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
    
    // MARK: - Tests
    
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
    
}
