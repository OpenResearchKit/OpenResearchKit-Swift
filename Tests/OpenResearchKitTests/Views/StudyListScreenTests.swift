//
//  StudyListScreenTests.swift
//  OpenResearchKit
//
//  Created by Codex on 18.05.26.
//

import XCTest
@testable import OpenResearchKit

final class StudyListScreenTests: XCTestCase {
    
    func testRegistryInitializerDerivesStudySectionsFromRegistry() {
        let activeStudy = makeStudy(identifier: "active")
        let availableStudy = makeStudy(identifier: "available")
        let completedStudy = makeStudy(identifier: "completed")
        let dismissedStudy = makeStudy(identifier: "dismissed")
        let studies = [activeStudy, availableStudy, completedStudy, dismissedStudy]
        defer { studies.forEach { try? $0.reset() } }
        
        giveConsent(to: activeStudy)
        completedStudy.setCompleted()
        dismissedStudy.isDismissedByUser = true
        
        let registry = StudyRegistry(studies: studies)
        let screen = StudyListScreen(studyRegistry: registry)
        
        XCTAssertTrue(reflectedStudy(named: "activeStudy", in: screen) === registry.currentActiveStudy)
        XCTAssertEqual(
            reflectedStudies(named: "availableStudies", in: screen).map(\.studyIdentifier),
            registry.recommendedStudies.map(\.studyIdentifier)
        )
        XCTAssertEqual(
            reflectedStudies(named: "participatedStudies", in: screen).map(\.studyIdentifier),
            Study.filterCompleted(studies: registry.studies).map(\.studyIdentifier)
        )
        XCTAssertEqual(
            reflectedStudies(named: "dismissedStudies", in: screen).map(\.studyIdentifier),
            registry.dismissedStudies.map(\.studyIdentifier)
        )
    }
    
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
        makeStudy(identifier: UUID().uuidString)
    }
    
    private func makeStudy(identifier: String) -> Study {
        DataDonationStudy(
            studyIdentifier: "study-list-screen-\(identifier)",
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
    
    private func giveConsent(to study: Study) {
        let expectation = expectation(description: "Study consent saved")
        
        study.saveUserConsentHasBeenGiven {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    private func reflectedStudy(named label: String, in screen: StudyListScreen) -> Study? {
        guard let value = reflectedValue(named: label, in: screen) else {
            return nil
        }
        
        if let study = value as? Study {
            return study
        }
        
        let optionalMirror = Mirror(reflecting: value)
        return optionalMirror.children.first?.value as? Study
    }
    
    private func reflectedStudies(named label: String, in screen: StudyListScreen) -> [Study] {
        reflectedValue(named: label, in: screen) as? [Study] ?? []
    }
    
    private func reflectedValue(named label: String, in screen: StudyListScreen) -> Any? {
        Mirror(reflecting: screen)
            .children
            .first { $0.label == label }?
            .value
    }
    
}
