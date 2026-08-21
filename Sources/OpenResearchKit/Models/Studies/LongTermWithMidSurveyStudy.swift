//
//  LongTermWithMidSurveyStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import SwiftUI

open class LongTermWithMidSurveyStudy: LongTermStudy, HasMidSurvey {

    let configuredMidStudySurveys: [MidStudySurvey]

    public var midStudySurveys: [MidStudySurvey] {
        midStudySurveysWithCompletionState
    }

    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        duration: TimeInterval,
        introductorySurveyURL: URL,
        midStudySurveys: [MidStudySurvey],
        concludingSurveyURL: URL,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] }
    ) {
        precondition(
            Self.hasConsistentSurveyIdentities(midStudySurveys),
            "Mid-study surveys with the same ID must use the same URL, showAfter, and expiresAfter values."
        )
        self.configuredMidStudySurveys = midStudySurveys.map {
            $0.reportingCompletion(false)
        }

        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurveyURL,
            concludingSurveyURL: concludingSurveyURL,
            participationIsPossible: participationIsPossible,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier,
            additionalQueryItems: additionalQueryItems
        )

        if hasUserGivenConsent {
            reconcileMidStudySurveyNotifications()
        }
    }

    /// Creates a long-term study with a fixed end date and fixed mid-study survey dates.
    ///
    /// The dates are converted to OpenResearchKit's relative representation using a
    /// persisted consent date when available, keeping the resulting schedule stable
    /// when the study is recreated on subsequent app launches.
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        studyEndDate: Date,
        introductorySurveyURL: URL,
        midStudySurveys: [AbsoluteDateMidStudySurvey],
        concludingSurveyURL: URL,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] }
    ) {
        let referenceDate = Self.absoluteScheduleReferenceDate(
            studyIdentifier: studyIdentifier,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier
        )
        let relativeMidStudySurveys = midStudySurveys.map {
            $0.relative(to: referenceDate)
        }

        precondition(
            Self.hasConsistentSurveyIdentities(relativeMidStudySurveys),
            "Mid-study surveys with the same ID must use the same URL, showAt, and expiresAt values."
        )
        self.configuredMidStudySurveys = relativeMidStudySurveys.map {
            $0.reportingCompletion(false)
        }

        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            duration: studyEndDate.timeIntervalSince(referenceDate),
            introductorySurveyURL: introductorySurveyURL,
            concludingSurveyURL: concludingSurveyURL,
            participationIsPossible: participationIsPossible,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier,
            additionalQueryItems: additionalQueryItems
        )

        if hasUserGivenConsent {
            reconcileMidStudySurveyNotifications()
        }
    }

    /// Compatibility initializer for studies that only have one mid-study survey.
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        duration: TimeInterval,
        introductorySurveyURL: URL,
        midStudySurvey: MidStudySurvey,
        concludingSurveyURL: URL,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] }
    ) {
        self.configuredMidStudySurveys = [
            midStudySurvey.reportingCompletion(false)
        ]

        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurveyURL,
            concludingSurveyURL: concludingSurveyURL,
            participationIsPossible: participationIsPossible,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier,
            additionalQueryItems: additionalQueryItems
        )

        if hasUserGivenConsent {
            reconcileMidStudySurveyNotifications()
        }
    }

    open override func registerNotifications() {
        super.registerNotifications()

        reconcileMidStudySurveyNotifications()
    }

    open override func setCompleted() {
        super.setCompleted()
        clearMidStudySurveyNotifications()
    }

    open override func didTerminateParticipation(terminationDate: Date) {
        clearMidStudySurveyNotifications()
        super.didTerminateParticipation(terminationDate: terminationDate)
    }

    open override func reset() throws {
        clearMidStudySurveyNotifications()
        try super.reset()
    }

    private func reconcileMidStudySurveyNotifications() {
        clearMidStudySurveyNotifications()

        guard let userConsentDate,
              !wasTerminatedBeforeCompletion,
              !isCompleted,
              !isDismissedByUser else {
            return
        }

        let now = dateGenerator.generate()
        let reminderDelay: TimeInterval = 3 * 24 * 60 * 60
        var registeredIdentifiers: [String] = []

        for midStudySurvey in pendingMidStudySurveys(at: now) {
            let notificationIdentifier = midStudySurveyNotificationIdentifier(
                for: midStudySurvey
            )
            let notificationDate = userConsentDate.addingTimeInterval(
                midStudySurvey.showAfter
            )
            let notificationInterval = notificationDate.timeIntervalSince(now)
            let expirationDate = midStudySurveyExpirationDate(for: midStudySurvey)
            let notificationPrecedesExpiration = expirationDate.map {
                notificationDate < $0
            } ?? true

            if notificationInterval >= 1 && notificationPrecedesExpiration {
                LocalPushController.shared.sendLocalNotification(
                    in: notificationInterval,
                    title: NSLocalizedString("Mid-Study Survey", bundle: Bundle.module, comment: ""),
                    subtitle: NSLocalizedString("Please fill out our short mid-study survey.", bundle: Bundle.module, comment: ""),
                    body: NSLocalizedString("It only takes 3 minutes to complete this survey.", bundle: Bundle.module, comment: ""),
                    identifier: notificationIdentifier
                )
                registeredIdentifiers.append(notificationIdentifier)
            }

            let reminderIdentifier = midStudySurveyReminderNotificationIdentifier(
                for: midStudySurvey
            )
            let reminderDate = notificationDate.addingTimeInterval(reminderDelay)
            let reminderInterval = reminderDate.timeIntervalSince(now)
            let reminderPrecedesExpiration = expirationDate.map {
                reminderDate < $0
            } ?? true

            if reminderInterval >= 1 && reminderPrecedesExpiration {
                LocalPushController.shared.sendLocalNotification(
                    in: reminderInterval,
                    title: "Survey Completion Still Pending",
                    subtitle: "Reminder: Please fill out our short mid-study survey.",
                    body: "It only takes about 3 minutes.",
                    identifier: reminderIdentifier
                )
                registeredIdentifiers.append(reminderIdentifier)
            }
        }

        store.update(
            Study.Keys.RegisteredMidStudySurveyNotificationIdentifiers,
            value: registeredIdentifiers.sorted()
        )
    }

    private func clearMidStudySurveyNotifications() {
        // Remove requests created by versions that only supported one survey.
        LocalPushController.clearNotifications(with: "mid-study-survey-notification")
        LocalPushController.clearNotifications(with: "mid-study-survey-notification-reminder")

        for identifier in registeredMidStudySurveyNotificationIdentifiers {
            LocalPushController.clearNotifications(with: identifier)
        }

        store.update(
            Study.Keys.RegisteredMidStudySurveyNotificationIdentifiers,
            value: [String]()
        )
    }

    private static func hasConsistentSurveyIdentities(
        _ surveys: [MidStudySurvey]
    ) -> Bool {
        var configurationByIdentifier: [String: MidStudySurvey] = [:]

        for survey in surveys {
            if let existingSurvey = configurationByIdentifier[survey.id] {
                guard existingSurvey.url == survey.url,
                      existingSurvey.showAfter.bitPattern == survey.showAfter.bitPattern,
                      existingSurvey.expiresAfter?.bitPattern
                        == survey.expiresAfter?.bitPattern else {
                    return false
                }
            } else {
                configurationByIdentifier[survey.id] = survey
            }
        }

        return true
    }

    // MARK: - HasMidSurvey -

    var midSurveyBannerView: AnyView {
        StudyBannerInvitation(study: self, surveyType: .mid)
            .toAnyView()
    }

}
