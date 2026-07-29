//
//  MidStudySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//


import CryptoKit
import Foundation

/// A survey that becomes available after a given amount of time in a study.
public struct MidStudySurvey: Identifiable, Sendable {

    public init(showAfter: TimeInterval, url: URL) {
        self.init(
            showAfter: showAfter,
            url: url,
            expiresAfter: nil
        )
    }

    public init(
        showAfter: TimeInterval,
        url: URL,
        expiresAfter: TimeInterval?
    ) {
        self.init(
            id: Self.defaultIdentifier(
                showAfter: showAfter,
                url: url
            ),
            showAfter: showAfter,
            url: url,
            expiresAfter: expiresAfter
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
            showAfter: showAfter,
            url: url,
            expiresAfter: expiresAfter,
            hasBeenCompleted: false
        )
    }

    private init(
        id: String,
        showAfter: TimeInterval,
        url: URL,
        expiresAfter: TimeInterval?,
        hasBeenCompleted: Bool
    ) {
        if let expiresAfter {
            precondition(
                showAfter.isFinite
                    && expiresAfter.isFinite
                    && expiresAfter > showAfter,
                "showAfter and expiresAfter must be finite, and expiresAfter must be greater than showAfter."
            )
        }

        self.id = id
        self.showAfter = showAfter
        self.url = url
        self.expiresAfter = expiresAfter
        self.hasBeenCompleted = hasBeenCompleted
    }

    /// An identity used to keep completion state and notifications attached to this
    /// logical survey across app launches and configuration reordering. Surveys with
    /// the same ID are treated as the same logical survey.
    public let id: String

    /// The time from the participant's consent date until this survey becomes available.
    public let showAfter: TimeInterval

    /// The base URL that is opened for this survey.
    public let url: URL

    /// The optional time from participant consent after which this survey is no
    /// longer available. This value and `showAfter` must be finite, and this value
    /// must be greater than `showAfter`.
    public let expiresAfter: TimeInterval?

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
            showAfter: showAfter,
            url: url,
            expiresAfter: expiresAfter,
            hasBeenCompleted: hasBeenCompleted
        )
    }

    private static func defaultIdentifier(
        showAfter: TimeInterval,
        url: URL
    ) -> String {
        let configuration = "\(url.absoluteString)|\(showAfter.bitPattern)"
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
