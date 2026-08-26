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
        
        XCTAssertEqual(
            midSurvey.schedule,
            .relativeToConsent(
                availableAfter: timeInterval,
                expiresAfter: nil
            )
        )
        XCTAssertEqual(midSurvey.url, url)
        XCTAssertFalse(midSurvey.hasBeenCompleted)
        
    }

    func testMidStudySurveyCanHaveExpirationDeadline() {
        let survey = MidStudySurvey(
            showAfter: 3600,
            url: URL(string: "https://example.com/mid-survey")!,
            expiresAfter: 7200
        )

        XCTAssertEqual(
            survey.schedule,
            .relativeToConsent(
                availableAfter: 3600,
                expiresAfter: 7200
            )
        )
        XCTAssertFalse(survey.hasBeenCompleted)
    }

    func testRelativeExpirationStartsWhenSurveyBecomesAvailable() {
        let consentDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let survey = MidStudySurvey(
            schedule: .relativeToConsent(
                availableAfter: 500,
                expiresAfter: 100
            ),
            url: URL(string: "https://example.com/mid-survey")!
        )

        XCTAssertEqual(
            survey.schedule.resolved(relativeTo: consentDate),
            MidStudySurveyWindow(
                availableAt: consentDate.addingTimeInterval(500),
                expiresAt: consentDate.addingTimeInterval(600)
            )
        )
    }

    func testOriginalInitializerCanBeUsedAsFunctionValue() {
        let initializer: (TimeInterval, URL) -> MidStudySurvey =
            MidStudySurvey.init(showAfter:url:)
        let url = URL(string: "https://example.com/mid-survey")!

        let survey = initializer(3600, url)

        XCTAssertEqual(
            survey.schedule,
            .relativeToConsent(
                availableAfter: 3600,
                expiresAfter: nil
            )
        )
        XCTAssertEqual(survey.url, url)
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

    func testFixedScheduleIsStoredAsOneValue() {
        let availableAt = Date(timeIntervalSinceReferenceDate: 1_000)
        let survey = MidStudySurvey(
            schedule: .fixedDates(
                availableAt: availableAt,
                expiresAfter: 500
            ),
            url: URL(string: "https://example.com/mid-survey")!
        )

        XCTAssertEqual(
            survey.schedule,
            .fixedDates(
                availableAt: availableAt,
                expiresAfter: 500
            )
        )
        XCTAssertEqual(
            survey.schedule.resolved(relativeTo: .distantPast),
            MidStudySurveyWindow(
                availableAt: availableAt,
                expiresAt: availableAt.addingTimeInterval(500)
            )
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
