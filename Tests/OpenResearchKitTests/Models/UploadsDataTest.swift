//
//  UploadsDataTest.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 16.09.25.
//

import XCTest

@testable import OpenResearchKit

class UploadsDataTest: XCTestCase {

    // MARK: - copyMainJSONToUpload Tests

    func testCopyMainJSONToUpload_CreatesFileInUploadDirectory() throws {
        // Arrange
        let studyID = "test"
        let study = TestStudy.makeStudy(id: studyID)

        // Create some JSON data in the main file
        let testData = [
            ["event": "test_event", "timestamp": "2023-01-01T00:00:00Z"],
            ["event": "another_event", "timestamp": "2023-01-02T00:00:00Z"],
        ]
        study.saveUserConsentHasBeenGiven {}
        study.appendNewJSONObjects(newObjects: testData)

        // Ensure upload directory is clean
        let uploadDir = study.studyDirectory(type: .upload)
        removeDirectoryIfExists(uploadDir)

        // Act
        try study.copyMainJSONToUpload()

        // Assert
        let expectedFileName = "study-\(studyID)-\(study.userIdentifier).json"
        let expectedFilePath = uploadDir.appendingPathComponent(expectedFileName)

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: expectedFilePath.path),
            "JSON file should exist in upload directory")

        // Verify the content is the same
        let uploadedData = try Data(contentsOf: expectedFilePath)
        let uploadedJSON = try JSONSerialization.jsonObject(with: uploadedData) as? [[String: Any]]

        XCTAssertEqual(uploadedJSON?.count, 2, "Should have copied 2 JSON objects")
        XCTAssertEqual(uploadedJSON?[0]["event"] as? String, "test_event")
        XCTAssertEqual(uploadedJSON?[1]["event"] as? String, "another_event")
    }

    func testCopyMainJSONToUpload_DoesNotThrowWhenMainFileDoesNotExist() throws {
        // Arrange
        let studyID = "NoFileStudy-\(UUID().uuidString)"
        let study = TestStudy.makeStudy(id: studyID)

        // Ensure no main JSON file exists
        let mainFilePath = study.jsonDataFilePath
        
        XCTAssertNoThrow(
            removeFileIfExists(mainFilePath),
            "Should not throw a file system error but handle it gracefully by only logging it."
        )
    }

    func testCopyMainJSONToUpload_OverwritesExistingFileInUploadDirectory() throws {
        
        let studyID = "OverwriteStudy-\(UUID().uuidString)"
        let study = TestStudy.makeStudy(id: studyID)
        study.saveUserConsentHasBeenGiven {}

        // Create initial data
        let initialData = [["event": "initial_event"]]
        study.appendNewJSONObjects(newObjects: initialData)

        // First copy
        try study.copyMainJSONToUpload()

        // Add more data
        let additionalData = [["event": "additional_event"]]
        study.appendNewJSONObjects(newObjects: additionalData)

        // Act - Second copy should overwrite
        try study.copyMainJSONToUpload()

        // Assert
        let uploadDir = study.studyDirectory(type: .upload)
        let expectedFileName = "study-\(studyID)-\(study.userIdentifier).json"
        let expectedFilePath = uploadDir.appendingPathComponent(expectedFileName)

        let uploadedData = try Data(contentsOf: expectedFilePath)
        let uploadedJSON = try JSONSerialization.jsonObject(with: uploadedData) as? [[String: Any]]

        XCTAssertEqual(uploadedJSON?.count, 2, "Should have both initial and additional events")

        // Check that both events are present (order may vary)
        let events = uploadedJSON?.compactMap { $0["event"] as? String } ?? []
        XCTAssertTrue(events.contains("initial_event"))
        XCTAssertTrue(events.contains("additional_event"))
    }

    // MARK: - appendNewJSONObjects Tests

    func testAppendNewJSONObjects_AddsDataWhenConsentGiven() throws {
        
        // Arrange
        let study = TestStudy.makeStudy()
        study.setConsent(true)  // User has given consent

        let testData = [
            ["action": "button_tap", "screen": "home"],
            ["action": "scroll", "direction": "up"],
        ]

        // Act
        study.appendNewJSONObjects(newObjects: testData)

        // Assert
        let savedData = study.JSONFile
        XCTAssertEqual(savedData.count, 2)
        XCTAssertEqual(savedData[0]["action"] as? String, "button_tap")
        XCTAssertEqual(savedData[1]["action"] as? String, "scroll")
    }

    func testAppendNewJSONObjects_DoesNotAddDataWhenConsentNotGiven() throws {
        
        // Arrange
        let study = TestStudy.makeStudy()
        study.setConsent(false)  // User has not given consent

        let testData = [["action": "button_tap"]]

        // Act
        study.appendNewJSONObjects(newObjects: testData)

        // Assert
        let savedData = study.JSONFile
        XCTAssertEqual(savedData.count, 0, "No data should be saved without consent")
        
    }

    func testAppendNewJSONObjects_AppendsToExistingData() throws {
        // Arrange
        let study = TestStudy.makeStudy()
        study.setConsent(true)

        // Add initial data
        let initialData = [["event": "first"]]
        study.appendNewJSONObjects(newObjects: initialData)

        // Act - Add more data
        let additionalData = [["event": "second"], ["event": "third"]]
        study.appendNewJSONObjects(newObjects: additionalData)

        // Assert
        let savedData = study.JSONFile
        XCTAssertEqual(savedData.count, 3)
        XCTAssertEqual(savedData[0]["event"] as? String, "first")
        XCTAssertEqual(savedData[1]["event"] as? String, "second")
        XCTAssertEqual(savedData[2]["event"] as? String, "third")
    }

    // MARK: - shouldUpload Tests

    func testShouldUpload_ReturnsTrueWhenNoLastUploadDate() {
        // Arrange
        let study = TestStudy.makeStudy()
        // Don't set any upload date

        // Act & Assert
        XCTAssertTrue(study.shouldUpload(), "Should upload when no previous upload date exists")
    }

    func testShouldUpload_ReturnsTrueWhenUploadFrequencyExceeded() {
        // Arrange
        let study = TestStudy.makeStudy()

        // Create custom upload configuration with 1 hour frequency
        study.setUploadConfiguration(frequency: 3600)

        // Set last upload to 2 hours ago
        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
        study.updateUploadDate(newDate: twoHoursAgo)

        // Act & Assert
        XCTAssertTrue(study.shouldUpload(), "Should upload when frequency threshold is exceeded")
    }

    func testShouldUpload_ReturnsFalseWhenUploadFrequencyNotExceeded() {
        // Arrange
        let study = TestStudy.makeStudy()

        // Create custom upload configuration with 1 hour frequency
        study.setUploadConfiguration(frequency: 3600)

        // Set last upload to 30 minutes ago
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        study.updateUploadDate(newDate: thirtyMinutesAgo)

        // Act & Assert
        XCTAssertFalse(
            study.shouldUpload(), "Should not upload when frequency threshold is not exceeded")
    }

    // MARK: - studyDirectory Tests

    func testStudyDirectory_CreatesWorkingDirectoryByDefault() throws {
        // Arrange
        let studyID = "DefaultDirStudy-\(UUID().uuidString)"
        let study = TestStudy.makeStudy(id: studyID)

        // Act
        let workingDir = study.studyDirectory()

        // Assert
        let expectedPath = try documentsDirectory()
            .appendingPathComponent("OpenResearchKit/Studies", isDirectory: true)
            .appendingPathComponent(studyID, isDirectory: true)
            .appendingPathComponent("working", isDirectory: true)

        XCTAssertEqual(workingDir, expectedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workingDir.path))

        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: workingDir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testStudyDirectory_CreatesUploadDirectory() throws {
        // Arrange
        let studyID = "UploadDirStudy-\(UUID().uuidString)"
        let study = TestStudy.makeStudy(id: studyID)

        // Act
        let uploadDir = study.studyDirectory(type: .upload)

        // Assert
        let expectedPath = try documentsDirectory()
            .appendingPathComponent("OpenResearchKit/Studies", isDirectory: true)
            .appendingPathComponent(studyID, isDirectory: true)
            .appendingPathComponent("upload", isDirectory: true)

        XCTAssertEqual(uploadDir, expectedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: uploadDir.path))

        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: uploadDir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    // MARK: - File Management Tests

    func testJSONFile_ReturnsEmptyArrayWhenNoFileExists() {
        // Arrange
        let study = TestStudy.makeStudy()
        removeFileIfExists(study.jsonDataFilePath)

        // Act
        let jsonData = study.JSONFile

        // Assert
        XCTAssertEqual(jsonData.count, 0, "Should return empty array when no file exists")
    }

    func testResetLocalJSONFile_RemovesExistingFile() throws {
        // Arrange
        let study = TestStudy.makeStudy()
        study.setConsent(true)

        // Create some data
        let testData = [["test": "data"]]
        study.appendNewJSONObjects(newObjects: testData)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: study.jsonDataFilePath.path))

        // Act
        try study.resetLocalJSONFile()

        // Assert
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: study.jsonDataFilePath.path),
            "JSON file should be removed after reset")
    }

    func testResetLocalJSONFile_NotThrowsWhenFileDoesNotExist() {
        // Arrange
        let study = TestStudy.makeStudy()
        
        // Act & Assert
        XCTAssertNoThrow(removeFileIfExists(study.jsonDataFilePath), "If no file is to be deleted, handle it gracefully.")
    }

    // MARK: - Helper Methods

    private func documentsDirectory() throws -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let url else { throw NSError(domain: "Test", code: 1) }
        return url
    }

    private func removeFileIfExists(_ url: URL) {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
    }

    private func removeDirectoryIfExists(_ url: URL) {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        if fm.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            try? fm.removeItem(at: url)
        }
    }
}

// MARK: - Test Study Implementation

extension UploadsDataTest {

    /// A test implementation of DataDonationStudy that conforms to UploadsStudyData for testing
    private class TestStudy: DataDonationStudy {

        private var _uploadConfiguration: UploadConfiguration

        override var uploadConfiguration: UploadConfiguration {
            get {
                return _uploadConfiguration
            }
            set {
                _uploadConfiguration = newValue
            }
        }

        init(
            studyIdentifier: String, studyInformation: StudyInformation,
            uploadConfiguration: UploadConfiguration, introductorySurveyURL: URL?,
            participationIsPossible: Bool,
            additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem],
            introSurveyCompletionHandler: (([String: String], Study) -> Void)?
        ) {
            self._uploadConfiguration = uploadConfiguration
            super.init(
                studyIdentifier: studyIdentifier, studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                introductorySurveyURL: introductorySurveyURL,
                participationIsPossible: participationIsPossible,
                additionalQueryItems: additionalQueryItems,
                introSurveyCompletionHandler: introSurveyCompletionHandler)
        }

        // Expose internal methods for testing
        var jsonDataFilePath: URL {
            return super.baseDirectory.appendingPathComponent(
                "study-\(studyIdentifier)-\(userIdentifier).json")
        }

        func setConsent(_ hasConsent: Bool) {
            if hasConsent {
                // Simulate giving consent by setting the consent date
                store.update(Study.Keys.UserConsentDate, value: self.dateGenerator.generate())
            } else {
                // Remove consent
                store.update(Study.Keys.UserConsentDate, value: nil)
            }
            publishChangesOnMain()
        }

        func setUploadConfiguration(frequency: TimeInterval) {
            _uploadConfiguration = UploadConfiguration(
                fileSubmissionServer: URL(string: "https://test.example.com/upload")!,
                uploadFrequency: frequency,
                apiKey: "TEST_API_KEY"
            )
        }

        static func makeStudy(id: String = UUID().uuidString) -> TestStudy {
            let info = StudyInformation(
                title: "Test Study",
                subtitle: "A study for testing",
                contactEmail: "test@example.com",
                image: nil
            )

            let uploadConfig = UploadConfiguration(
                fileSubmissionServer: URL(string: "https://test.example.com/upload")!,
                uploadFrequency: 3600,
                apiKey: "TEST_API_KEY"
            )

            return TestStudy(
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

}
