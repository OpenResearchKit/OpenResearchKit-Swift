//
//  AbsoluteDateMidStudySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 24.08.26.
//


import CryptoKit
import Foundation

/// A mid-study survey configured with fixed calendar dates.
///
/// `LongTermWithMidSurveyStudy` converts these dates to the relative intervals used
/// internally by OpenResearchKit. When the participant has already consented, their
/// persisted consent date is used as the reference so the schedule remains stable
/// across app launches.
public struct AbsoluteDateMidStudySurvey: Identifiable, Sendable {

    public init(
        showAt: Date,
        url: URL,
        expiresAt: Date? = nil
    ) {
        self.init(
            id: Self.defaultIdentifier(showAt: showAt, url: url),
            showAt: showAt,
            url: url,
            expiresAt: expiresAt
        )
    }

    /// Creates a survey with an explicit identity that remains stable if its URL or
    /// schedule changes in a later app version. Use a unique ID for each logical
    /// survey in a study.
    public init(
        id: String,
        showAt: Date,
        url: URL,
        expiresAt: Date? = nil
    ) {
        precondition(
            showAt.timeIntervalSinceReferenceDate.isFinite,
            "showAt must be finite."
        )

        if let expiresAt {
            precondition(
                expiresAt.timeIntervalSinceReferenceDate.isFinite
                    && expiresAt > showAt,
                "expiresAt must be finite and greater than showAt."
            )
        }

        self.id = id
        self.showAt = showAt
        self.url = url
        self.expiresAt = expiresAt
    }

    public let id: String
    public let showAt: Date
    public let url: URL
    public let expiresAt: Date?

    func relative(to referenceDate: Date) -> MidStudySurvey {
        MidStudySurvey(
            id: id,
            showAfter: showAt.timeIntervalSince(referenceDate),
            url: url,
            expiresAfter: expiresAt?.timeIntervalSince(referenceDate)
        )
    }

    private static func defaultIdentifier(showAt: Date, url: URL) -> String {
        let configuration = "\(url.absoluteString)|\(showAt.timeIntervalSinceReferenceDate.bitPattern)"
        return MidStudySurvey.stableDigest(configuration)
    }

}
