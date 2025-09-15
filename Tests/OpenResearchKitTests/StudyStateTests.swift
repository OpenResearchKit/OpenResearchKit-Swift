//
//  StudyStateTests.swift
//  OpenResearchKit-Swift
//
//  Created by Lennart Fischer on 12.09.25.
//

import XCTest

@testable import OpenResearchKit

final class StudyStateTests: XCTestCase {

    private var study: Study!
    private let studyID = "TestStudy-\(UUID().uuidString)"

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        study = Dummy.makeStudy(id: studyID)
    }

    override func tearDown() {
        try? study.reset()
        study = nil
        super.tearDown()
    }

    // MARK: - Test helpers

    private struct Dummy {
        static func makeStudy(
            id: String = UUID().uuidString,
            introURL: URL? = URL(string: "https://example.com/intro")
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
                introductorySurveyURL: introURL,
                participationIsPossible: true,
                additionalQueryItems: { _ in [URLQueryItem(name: "test", value: "true")] },
                introSurveyCompletionHandler: nil
            )
        }
    }

    // MARK: - Tests

    func test_userIdentifier_isGeneratedAndPersisted() {

        let initialUserID = study.userIdentifier

        XCTAssertFalse(initialUserID.isEmpty)

        let subsequentUserID = study.userIdentifier

        XCTAssertEqual(initialUserID, subsequentUserID, "User ID should be stable across accesses.")

        let newStudyInstance = Dummy.makeStudy(id: studyID)

        XCTAssertEqual(
            newStudyInstance.userIdentifier, initialUserID,
            "New instance should load the persisted user ID.")
    }

    func test_userConsent_isSavedAndReflected() {

        XCTAssertFalse(study.hasUserGivenConsent, "Study should not have consent initially.")

        let consentDate = Date()
        let expectation = XCTestExpectation(
            description: "Save user consent completion handler called.")
        study.saveUserConsentHasBeenGiven(consentTimestamp: consentDate) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(study.hasUserGivenConsent, "Study should have consent after saving.")
        XCTAssertNotNil(study.store.get(Study.Keys.UserConsentDate, type: Date.self))
    }

    func test_shouldDisplayIntroductorySurvey_isTrueByDefault() {
        
        XCTAssertTrue(study.shouldDisplayIntroductorySurvey, "Should display intro survey by default.")
        
    }

    func test_shouldDisplayIntroductorySurvey_isFalseAfterConsent() {
        
        study.saveUserConsentHasBeenGiven(consentTimestamp: Date()) {}

        XCTAssertFalse(study.shouldDisplayIntroductorySurvey, "Should not display intro survey after giving consent.")
        
    }

    func test_shouldDisplayIntroductorySurvey_isFalseWhenDismissed() {
        
        study.isDismissedByUser = true

        // Assert
        XCTAssertFalse(study.shouldDisplayIntroductorySurvey, "Should not display intro survey after being dismissed.")
        
    }

    func test_shouldDisplayIntroductorySurvey_isFalseWhenParticipationNotPossible() {
        
        study.participationIsPossible = false
        
        XCTAssertFalse(study.shouldDisplayIntroductorySurvey, "Should not display intro survey if participation is not possible.")
        
    }

    func test_shouldDisplayIntroductorySurvey_isFalseWithoutURL() {
        
        let studyWithoutURL = Dummy.makeStudy(id: "no-url-study", introURL: nil)

        XCTAssertFalse(studyWithoutURL.shouldDisplayIntroductorySurvey, "Should not display intro survey if the URL is nil.")
        
    }

    func test_surveyUrl_generation() {

        let userID = study.userIdentifier
        let introURL = study.surveyUrl(for: .introductory)

        XCTAssertNotNil(introURL)

        let components = URLComponents(url: introURL!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.scheme, "https")
        XCTAssertEqual(components?.host, "example.com")
        XCTAssertEqual(components?.path, "/intro")
        XCTAssertTrue(
            components?.queryItems?.contains(URLQueryItem(name: "uuid", value: userID)) ?? false)
        XCTAssertTrue(
            components?.queryItems?.contains(URLQueryItem(name: "test", value: "true")) ?? false,
            "Additional query items should be present.")

    }

    func test_reset_clearsStudyData() throws {

        let initialUserID = study.userIdentifier
        study.saveUserConsentHasBeenGiven(consentTimestamp: Date()) {}

        let fileManager = FileManager.default
        let workingDir = study.studyDirectory(type: .working)
        let dummyFileURL = workingDir.appendingPathComponent("test.txt")
        fileManager.createFile(atPath: dummyFileURL.path, contents: "test".data(using: .utf8))

        XCTAssertTrue(study.hasUserGivenConsent)
        XCTAssertTrue(fileManager.fileExists(atPath: dummyFileURL.path))

        try study.reset()

        XCTAssertFalse(study.hasUserGivenConsent, "Consent should be cleared after reset.")
        XCTAssertFalse(
            fileManager.fileExists(atPath: dummyFileURL.path),
            "Files in working directory should be deleted.")

        let newUserID = study.userIdentifier
        XCTAssertNotEqual(
            initialUserID, newUserID, "A new user ID should be generated after a reset.")
    }

}
