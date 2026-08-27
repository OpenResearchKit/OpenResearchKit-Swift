//
//  MidStudySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//


import CryptoKit
import Foundation



/// A survey that becomes available during a study according to one schedule.
public struct MidStudySurvey: Identifiable, Sendable {

    public init(showAfter: TimeInterval, url: URL) {
        self.init(
            schedule: .relativeToConsent(
                availableAfter: showAfter,
                expiresAfter: nil
            ),
            url: url
        )
    }

    public init(
        showAfter: TimeInterval,
        url: URL,
        expiresAfter: TimeInterval?
    ) {
        self.init(
            schedule: .relativeToConsent(
                availableAfter: showAfter,
                expiresAfter: expiresAfter
            ),
            url: url
        )
    }

    public init(
        schedule: MidStudySurveySchedule,
        url: URL
    ) {
        self.init(
            id: Self.defaultIdentifier(schedule: schedule, url: url),
            schedule: schedule,
            url: url
        )
    }

    /// Creates a survey with an explicit identity that remains stable if its URL or
    /// schedule changes in a later app version. Use a unique ID for each logical
    /// survey in a study.
    public init(
        id: String,
        showAfter: TimeInterval,
        url: URL,
        expiresAfter: TimeInterval? = nil
    ) {
        self.init(
            id: id,
            schedule: .relativeToConsent(
                availableAfter: showAfter,
                expiresAfter: expiresAfter
            ),
            url: url
        )
    }

    /// Creates a survey with one explicit schedule and a stable identity.
    public init(
        id: String,
        schedule: MidStudySurveySchedule,
        url: URL
    ) {
        self.init(
            id: id,
            schedule: schedule,
            url: url,
            hasBeenCompleted: false
        )
    }

    private init(
        id: String,
        schedule: MidStudySurveySchedule,
        url: URL,
        hasBeenCompleted: Bool
    ) {
        self.id = id
        self.schedule = schedule.validated()
        self.url = url
        self.hasBeenCompleted = hasBeenCompleted
    }

    /// An identity used to keep completion state and notifications attached to this
    /// logical survey across app launches and configuration reordering. Surveys with
    /// the same ID are treated as the same logical survey.
    public let id: String

    /// The single rule that determines this survey's availability window.
    public let schedule: MidStudySurveySchedule

    /// The base URL that is opened for this survey.
    public let url: URL

    /// Whether this survey has been completed in the study from which this value
    /// was retrieved. A newly configured survey starts incomplete. Re-read the
    /// study's `midStudySurveys` after state changes.
    public let hasBeenCompleted: Bool

    /// Stable across launches and array reordering so completion state stays attached to
    /// the configured survey rather than its position in the array.
    var completionIdentifier: String {
        id
    }

    func reportingCompletion(_ hasBeenCompleted: Bool) -> Self {
        Self(
            id: id,
            schedule: schedule,
            url: url,
            hasBeenCompleted: hasBeenCompleted
        )
    }

    private static func defaultIdentifier(
        schedule: MidStudySurveySchedule,
        url: URL
    ) -> String {
        let configuration = "\(url.absoluteString)|\(schedule.defaultIdentifierComponent)"
        return stableDigest(configuration)
    }

    static func stableDigest(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))

        return digest.map { byte in
            let hexadecimal = String(byte, radix: 16)
            return byte < 16 ? "0\(hexadecimal)" : hexadecimal
        }
        .joined()
    }

}
