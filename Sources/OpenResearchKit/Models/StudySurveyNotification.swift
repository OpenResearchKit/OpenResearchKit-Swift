//
//  StudySurveyNotification.swift
//  OpenResearchKit
//

import Foundation

public enum StudySurveyNotification {

    public static let categoryIdentifier = "open-research-kit-study-survey"

    public static func matches(categoryIdentifier: String) -> Bool {
        categoryIdentifier == self.categoryIdentifier
            || legacyCategoryIdentifiers.contains(categoryIdentifier)
            || categoryIdentifier.hasPrefix("mid-study-survey|")
    }

    private static let legacyCategoryIdentifiers: Set<String> = [
        "survey-completion-notification",
        "survey-completion-notification-reminder",
        "mid-study-survey-notification",
        "mid-study-survey-notification-reminder"
    ]

}
