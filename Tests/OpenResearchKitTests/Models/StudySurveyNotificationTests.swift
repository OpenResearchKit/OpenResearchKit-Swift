//
//  StudySurveyNotificationTests.swift
//  OpenResearchKit
//

import Testing

@testable import OpenResearchKit

struct StudySurveyNotificationTests {

    @Test("The stable survey category is recognized")
    func stableCategoryIsRecognized() {
        #expect(StudySurveyNotification.matches(
            categoryIdentifier: StudySurveyNotification.categoryIdentifier
        ))
    }

    @Test(
        "Legacy survey categories are recognized",
        arguments: [
            "survey-completion-notification",
            "survey-completion-notification-reminder",
            "mid-study-survey-notification",
            "mid-study-survey-notification-reminder",
            "mid-study-survey|a-stable-survey-hash"
        ]
    )
    func legacyCategoryIsRecognized(_ categoryIdentifier: String) {
        #expect(StudySurveyNotification.matches(
            categoryIdentifier: categoryIdentifier
        ))
    }

    @Test("An unrelated notification category is not recognized")
    func unrelatedCategoryIsNotRecognized() {
        #expect(!StudySurveyNotification.matches(
            categoryIdentifier: "request-breathing-exercise"
        ))
    }

}
