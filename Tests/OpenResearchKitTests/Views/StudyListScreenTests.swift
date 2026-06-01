//
//  StudyListScreenTests.swift
//  OpenResearchKit
//
//  Created by Codex on 18.05.26.
//

import XCTest
@testable import OpenResearchKit

final class StudyListScreenTests: XCTestCase {
    
    func testDismissedSectionIsHiddenOutsideDebugAndTestFlight() {
        let study = makeStudy()
        defer { try? study.reset() }
        
        XCTAssertFalse(
            StudyListScreen.shouldShowDismissedStudiesSection(
                dismissedStudies: [study],
                shouldShowDebugTools: false
            )
        )
    }
    
    func testDismissedSectionIsHiddenWhenThereAreNoDismissedStudies() {
        XCTAssertFalse(
            StudyListScreen.shouldShowDismissedStudiesSection(
                dismissedStudies: [],
                shouldShowDebugTools: true
            )
        )
    }
    
    func testDismissedSectionIsShownInDebugOrTestFlightWhenDismissedStudiesExist() {
        let study = makeStudy()
        defer { try? study.reset() }
        
        XCTAssertTrue(
            StudyListScreen.shouldShowDismissedStudiesSection(
                dismissedStudies: [study],
                shouldShowDebugTools: true
            )
        )
    }
    
    private func makeStudy() -> Study {
        DataDonationStudy(
            studyIdentifier: "study-list-screen-\(UUID().uuidString)",
            studyInformation: StudyInformation(
                title: "Study",
                subtitle: "",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                serverURL: URL(string: "https://example.com/upload")!,
                uploadFrequency: 3600,
                apiKey: "TEST_API_KEY"
            ),
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            participationIsPossible: true
        )
    }
    
}

