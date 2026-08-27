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

    func midSurveyBannerView(for survey: MidStudySurvey) -> AnyView

    /// Whether every configured mid-study survey has been completed.
    /// This remains `false` when no mid-study surveys are configured.
    var hasCompletedMidSurvey: Bool { get }

    var midStudySurveyToDisplay: MidStudySurvey? { get }

    func showMidStudySurvey()

}

extension HasMidSurvey {

    /// Mid-study surveys in chronological order. Surveys with the same identity are
    /// treated as one logical survey. Before consent, schedules on one timeline are
    /// ordered by their configured boundary. A mixed timeline keeps configuration
    /// order until the consent date lets both schedule kinds resolve to dates.
    var scheduledMidStudySurveys: [MidStudySurvey] {
        var seenIdentifiers = Set<String>()

        let uniqueSurveys: [MidStudySurvey] = configuredMidStudySurveys.compactMap {
            survey -> MidStudySurvey? in
            guard seenIdentifiers.insert(survey.completionIdentifier).inserted else {
                return nil
            }

            return survey
        }

        guard userConsentDate != nil else {
            guard let firstSurvey = uniqueSurveys.first,
                  uniqueSurveys.dropFirst().allSatisfy({
                    firstSurvey.schedule.compareAvailability(to: $0.schedule) != nil
                  }) else {
                return uniqueSurveys
            }

            return uniqueSurveys
                .enumerated()
                .sorted { lhs, rhs in
                    switch lhs.element.schedule.compareAvailability(
                        to: rhs.element.schedule
                    ) {
                    case .orderedAscending:
                        return true
                    case .orderedDescending:
                        return false
                    case .orderedSame, nil:
                        return lhs.offset < rhs.offset
                    }
                }
                .map { $0.element }
        }

        return uniqueSurveys
            .enumerated()
            .sorted { lhs, rhs in
                guard let lhsDate = midStudySurveyAvailabilityDate(for: lhs.element),
                      let rhsDate = midStudySurveyAvailabilityDate(for: rhs.element),
                      lhsDate != rhsDate else {
                    return lhs.offset < rhs.offset
                }

                return lhsDate < rhsDate
            }
            .map { $0.element }
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
        // still sorted independently by the resolved availability date.
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

    /// The due mid-study survey that should be displayed, or `nil` when no
    /// survey is eligible for presentation.
    ///
    /// - Complexity: O(*n* log *n*), where *n* is the number of configured
    ///   mid-study surveys.
    public var midStudySurveyToDisplay: MidStudySurvey? {
        midStudySurveyToDisplay(at: dateGenerator.generate())
    }

    func midStudySurveyToDisplay(at date: Date) -> MidStudySurvey? {
        guard !wasTerminatedBeforeCompletion,
              !isCompleted,
              !isDismissedByUser else {
            return nil
        }

        guard let nextMidStudySurvey = pendingMidStudySurveys(at: date).first,
              let availabilityDate = midStudySurveyAvailabilityDate(
                for: nextMidStudySurvey
              ) else {
            return nil
        }

        return availabilityDate <= date ? nextMidStudySurvey : nil
    }

    public func showMidStudySurvey() {
        guard let midStudySurvey = nextMidStudySurvey,
              let study = self as? Study else {
            return
        }

        showView(
            SurveyWebView(
                study: study,
                midStudySurvey: midStudySurvey
            )
        )
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

    func midStudySurveyAvailabilityDate(for survey: MidStudySurvey) -> Date? {
        midStudySurveyWindow(for: survey)?.availableAt
    }

    func midStudySurveyExpirationDate(for survey: MidStudySurvey) -> Date? {
        midStudySurveyWindow(for: survey)?.expiresAt
    }

    private func midStudySurveyWindow(
        for survey: MidStudySurvey
    ) -> MidStudySurveyWindow? {
        guard let userConsentDate else {
            return nil
        }

        return survey.schedule.resolved(relativeTo: userConsentDate)
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
