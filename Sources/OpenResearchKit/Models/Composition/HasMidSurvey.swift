//
//  HasMidSurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import SwiftUI

protocol HasMidSurvey: AnyObject, GeneralStudy {

    var configuredMidStudySurveys: [MidStudySurvey] { get }

    var midStudySurveys: [MidStudySurvey] { get }

    var midSurveyBannerView: AnyView { get }

    /// Whether every configured mid-study survey has been completed.
    /// This remains `false` when no mid-study surveys are configured.
    var hasCompletedMidSurvey: Bool { get }

    /// A mid-study survey should be displayed after consent as soon as the
    /// next incomplete survey's `showAfter` interval has elapsed.
    var shouldDisplayMidSurvey: Bool { get }

    func showMidStudySurvey()

}

extension HasMidSurvey {

    /// Mid-study surveys in chronological order. Surveys with the same identity are
    /// treated as one logical survey.
    var scheduledMidStudySurveys: [MidStudySurvey] {
        var seenIdentifiers = Set<String>()

        return configuredMidStudySurveys
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.showAfter == rhs.element.showAfter {
                    return lhs.offset < rhs.offset
                }

                return lhs.element.showAfter < rhs.element.showAfter
            }
            .compactMap { _, survey in
                guard seenIdentifiers.insert(survey.completionIdentifier).inserted else {
                    return nil
                }

                return survey
            }
    }

    /// Surveys that still need a response and have not reached their deadline.
    var pendingMidStudySurveys: [MidStudySurvey] {
        pendingMidStudySurveys(at: dateGenerator.generate())
    }

    func pendingMidStudySurveys(at date: Date) -> [MidStudySurvey] {
        let completedIdentifiers = completedMidStudySurveyIdentifiers
        return scheduledMidStudySurveys.filter {
            !completedIdentifiers.contains($0.completionIdentifier)
                && !hasMidStudySurveyExpired($0, at: date)
        }
    }

    var nextMidStudySurvey: MidStudySurvey? {
        pendingMidStudySurveys.first
    }

    var nextMidStudySurveyIdentifier: String? {
        nextMidStudySurvey?.completionIdentifier
    }

    public var hasCompletedMidSurvey: Bool {
        let completedIdentifiers = completedMidStudySurveyIdentifiers

        return !scheduledMidStudySurveys.isEmpty
            && scheduledMidStudySurveys.allSatisfy {
                completedIdentifiers.contains($0.completionIdentifier)
            }
    }

    /// Whether every configured survey was either completed or expired.
    var hasResolvedMidStudySurveys: Bool {
        !scheduledMidStudySurveys.isEmpty && pendingMidStudySurveys.isEmpty
    }

    var midStudySurveysWithCompletionState: [MidStudySurvey] {
        let completedIdentifiers = completedMidStudySurveyIdentifiers

        return configuredMidStudySurveys.map { survey in
            survey.reportingCompletion(
                completedIdentifiers.contains(survey.completionIdentifier)
            )
        }
    }

    private var completedMidStudySurveyIdentifiers: Set<String> {
        if let identifiers = store.get(
            Study.Keys.CompletedMidStudySurveyIdentifiers,
            type: [String].self
        ) {
            return Set(identifiers)
        }

        var identifiers = Set<String>()

        // The first configured entry is the compatibility slot for the survey
        // previously supplied through the singular initializer. Presentation is
        // still sorted independently by `showAfter`.
        if store.get(Study.Keys.HasCompletedMidSurvey, type: Bool.self) == true,
           let firstSurvey = configuredMidStudySurveys.first {
            identifiers.insert(firstSurvey.completionIdentifier)
        }

        // Persist even an empty array so the migrated representation becomes
        // authoritative and the legacy Boolean is not re-applied later.
        store.update(
            Study.Keys.CompletedMidStudySurveyIdentifiers,
            value: identifiers.sorted()
        )

        return identifiers
    }

    public var shouldDisplayMidSurvey: Bool {
        let now = dateGenerator.generate()

        guard let userConsentDate,
              let nextMidStudySurvey = pendingMidStudySurveys(at: now).first else {
            return false
        }

        let showAfterDate = userConsentDate.addingTimeInterval(nextMidStudySurvey.showAfter)
        return showAfterDate <= now
    }

    public func showMidStudySurvey() {
        guard nextMidStudySurvey != nil else {
            return
        }

        if let study = self as? Study {
            self.showView(SurveyWebView(surveyType: .mid, study: study))
        }
    }

    public func completeMidSurvey() {
        completeMidSurvey(identifier: nil)
    }

    func completeMidSurvey(identifier: String?) {
        let survey: MidStudySurvey?

        if let identifier {
            survey = scheduledMidStudySurveys.first {
                $0.completionIdentifier == identifier
            }
        } else {
            survey = nextMidStudySurvey
        }

        guard let survey else {
            return
        }

        guard !hasMidStudySurveyExpired(survey) else {
            return
        }

        var completedIdentifiers = completedMidStudySurveyIdentifiers
        guard completedIdentifiers.insert(survey.completionIdentifier).inserted else {
            return
        }

        store.update(
            Study.Keys.CompletedMidStudySurveyIdentifiers,
            value: completedIdentifiers.sorted()
        )

        if let legacySurvey = configuredMidStudySurveys.first {
            store.update(
                Study.Keys.HasCompletedMidSurvey,
                value: completedIdentifiers.contains(legacySurvey.completionIdentifier)
            )
        }

        let notificationIdentifier = midStudySurveyNotificationIdentifier(for: survey)
        let reminderIdentifier = midStudySurveyReminderNotificationIdentifier(for: survey)
        let clearedNotificationIdentifiers = Set([
            notificationIdentifier,
            reminderIdentifier
        ])
        let remainingNotificationIdentifiers = registeredMidStudySurveyNotificationIdentifiers
            .filter { !clearedNotificationIdentifiers.contains($0) }

        store.update(
            Study.Keys.RegisteredMidStudySurveyNotificationIdentifiers,
            value: remainingNotificationIdentifiers
        )

        publishChangesOnMain {
            LocalPushController.clearNotifications(with: notificationIdentifier)
            LocalPushController.clearNotifications(with: reminderIdentifier)

            // Clear requests created by versions that only supported one survey.
            LocalPushController.clearNotifications(with: "mid-study-survey-notification")
            LocalPushController.clearNotifications(with: "mid-study-survey-notification-reminder")
        }
    }

    func midStudySurvey(identifier: String?) -> MidStudySurvey? {
        guard let identifier else {
            return nextMidStudySurvey
        }

        guard let survey = scheduledMidStudySurveys.first(where: {
            $0.completionIdentifier == identifier
        }) else {
            return nil
        }

        return hasMidStudySurveyExpired(survey) ? nil : survey
    }

    func midStudySurveyExpirationDate(for survey: MidStudySurvey) -> Date? {
        guard let userConsentDate, let expiresAfter = survey.expiresAfter else {
            return nil
        }

        return userConsentDate.addingTimeInterval(expiresAfter)
    }

    func hasMidStudySurveyExpired(_ survey: MidStudySurvey) -> Bool {
        hasMidStudySurveyExpired(survey, at: dateGenerator.generate())
    }

    private func hasMidStudySurveyExpired(
        _ survey: MidStudySurvey,
        at date: Date
    ) -> Bool {
        guard let expirationDate = midStudySurveyExpirationDate(for: survey) else {
            return false
        }

        return expirationDate <= date
    }

    func midStudySurveyNotificationIdentifier(for survey: MidStudySurvey) -> String {
        midStudySurveyNotificationIdentifier(
            for: survey,
            kind: "notification"
        )
    }

    func midStudySurveyReminderNotificationIdentifier(for survey: MidStudySurvey) -> String {
        midStudySurveyNotificationIdentifier(
            for: survey,
            kind: "reminder"
        )
    }

    var registeredMidStudySurveyNotificationIdentifiers: [String] {
        store.get(
            Study.Keys.RegisteredMidStudySurveyNotificationIdentifiers,
            type: [String].self
        ) ?? []
    }

    private func midStudySurveyNotificationIdentifier(
        for survey: MidStudySurvey,
        kind: String
    ) -> String {
        let components = [
            studyIdentifier,
            survey.completionIdentifier,
            kind
        ]
        let lengthPrefixedComponents = components
            .map { "\($0.utf8.count):\($0)" }
            .joined()

        return "mid-study-survey|\(MidStudySurvey.stableDigest(lengthPrefixedComponents))"
    }

}
