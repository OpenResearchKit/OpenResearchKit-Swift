//
//  MidStudySurveyTest.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class MidStudySurveyTest: XCTestCase {
    
    func testMidStudySurveyInitialization() {
        
        let url = URL(string: "https://example.com/mid-survey")!
        let timeInterval: TimeInterval = 3600  // 1 hour
        
        let midSurvey = MidStudySurvey(showAfter: timeInterval, url: url)
        
        XCTAssertEqual(midSurvey.showAfter, timeInterval)
        XCTAssertEqual(midSurvey.url, url)
        XCTAssertNil(midSurvey.expiresAfter)
        
    }

    func testMidStudySurveyCanHaveExpirationDeadline() {
        let survey = MidStudySurvey(
            showAfter: 3600,
            url: URL(string: "https://example.com/mid-survey")!,
            expiresAfter: 7200
        )

        XCTAssertEqual(survey.expiresAfter, 7200)
    }

    func testOriginalInitializerCanBeUsedAsFunctionValue() {
        let initializer: (TimeInterval, URL) -> MidStudySurvey =
            MidStudySurvey.init(showAfter:url:)
        let url = URL(string: "https://example.com/mid-survey")!

        let survey = initializer(3600, url)

        XCTAssertEqual(survey.showAfter, 3600)
        XCTAssertEqual(survey.url, url)
        XCTAssertNil(survey.expiresAfter)
    }

    func testCompletionIdentifierIsDeterministicForSameConfiguration() {
        let url = URL(string: "https://example.com/mid-survey")!
        let first = MidStudySurvey(showAfter: 3600, url: url)
        let second = MidStudySurvey(showAfter: 3600, url: url)

        XCTAssertEqual(first.completionIdentifier, second.completionIdentifier)
    }

    func testCompletionIdentifierDistinguishesScheduleAndUrl() {
        let url = URL(string: "https://example.com/mid-survey")!
        let survey = MidStudySurvey(showAfter: 3600, url: url)
        let differentlyScheduledSurvey = MidStudySurvey(showAfter: 7200, url: url)
        let differentURLSurvey = MidStudySurvey(
            showAfter: 3600,
            url: URL(string: "https://example.com/other-mid-survey")!
        )

        XCTAssertNotEqual(
            survey.completionIdentifier,
            differentlyScheduledSurvey.completionIdentifier
        )
        XCTAssertNotEqual(
            survey.completionIdentifier,
            differentURLSurvey.completionIdentifier
        )
    }

    func testAddingExpirationDoesNotChangeDefaultIdentifier() {
        let url = URL(string: "https://example.com/mid-survey")!
        let surveyWithoutExpiration = MidStudySurvey(showAfter: 3600, url: url)
        let expiringSurvey = MidStudySurvey(
            showAfter: 3600,
            url: url,
            expiresAfter: 7200
        )

        XCTAssertEqual(
            surveyWithoutExpiration.completionIdentifier,
            expiringSurvey.completionIdentifier
        )
    }

    func testExplicitIdentifierRemainsStableWhenConfigurationChanges() {
        let first = MidStudySurvey(
            id: "week-one",
            showAfter: 3600,
            url: URL(string: "https://example.com/original")!
        )
        let updated = MidStudySurvey(
            id: "week-one",
            showAfter: 7200,
            url: URL(string: "https://example.com/updated")!,
            expiresAfter: 10_800
        )

        XCTAssertEqual(first.id, "week-one")
        XCTAssertEqual(first.completionIdentifier, updated.completionIdentifier)
    }

    func testDefaultIdentifierDoesNotExposeSurveyUrl() {
        let survey = MidStudySurvey(
            showAfter: 3600,
            url: URL(string: "https://example.com/private-survey")!
        )

        XCTAssertFalse(survey.id.contains("example.com"))
        XCTAssertFalse(survey.id.contains("private-survey"))
    }
    
}
