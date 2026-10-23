//
//  Study+SurveyBanner.swift
//
//
//  Created by Lennart Fischer on 26.08.26.
//

import Foundation

/// The survey of a study that is due now and should be shown as a banner.
public enum StudySurveyBanner: Equatable {
    case mid(MidStudySurvey)
    case completion

    public static func == (lhs: StudySurveyBanner, rhs: StudySurveyBanner) -> Bool {
        switch (lhs, rhs) {
        case let (.mid(lhsSurvey), .mid(rhsSurvey)):
            return lhsSurvey.completionIdentifier == rhsSurvey.completionIdentifier
        case (.completion, .completion):
            return true
        case (.mid, _), (.completion, _):
            return false
        }
    }
}

extension Study {

    /// The survey that is due at the given date. The conclusion survey has priority over mid-study surveys.
    ///
    /// No survey is due after the conclusion survey was completed, even while a study waits for its
    /// completion acknowledgement.
    func surveyBanner(at date: Date) -> StudySurveyBanner? {
        if let terminationSurveyStudy = self as? (any HasTerminationSurvey) {
            if terminationSurveyStudy.hasCompletedTerminationSurvey {
                return nil
            }

            if hasConclusionSurvey, terminationSurveyStudy.shouldDisplayTerminationSurvey(at: date) {
                return .completion
            }
        }

        if let midSurveyStudy = self as? (any HasMidSurvey),
           let survey = midSurveyStudy.midStudySurveyToDisplay(at: date) {
            return .mid(survey)
        }

        return nil
    }

    /// The next date after the given date at which the due survey can change without a change to the study,
    /// because a survey becomes available or expires. Returns `nil` when no such date is scheduled.
    func nextSurveyBannerChangeDate(after date: Date) -> Date? {
        var dates: [Date] = []

        if let terminationSurveyStudy = self as? (any HasTerminationSurvey) {
            guard !terminationSurveyStudy.hasCompletedTerminationSurvey else {
                return nil
            }

            if hasConclusionSurvey, let actualStudyEndDate = terminationSurveyStudy.actualStudyEndDate {
                dates.append(actualStudyEndDate)
            }
        }

        if let midSurveyStudy = self as? (any HasMidSurvey) {
            for survey in midSurveyStudy.pendingMidStudySurveys(at: date) {
                if let availabilityDate = midSurveyStudy.midStudySurveyAvailabilityDate(for: survey) {
                    dates.append(availabilityDate)
                }

                if let expirationDate = midSurveyStudy.midStudySurveyExpirationDate(for: survey) {
                    dates.append(expirationDate)
                }
            }
        }

        return dates
            .filter { $0 > date }
            .min()
    }

    /// A conclusion survey is due only if one is configured and the study is not completed yet.
    private var hasConclusionSurvey: Bool {
        !isCompleted && (self as? LongTermStudy)?.concludingSurveyURL != nil
    }

    /// Presents the survey that is due now, using the shared banner priority.
    @discardableResult
    public func showDueSurveyIfNeeded(at date: Date? = nil) -> Bool {
        switch surveyBanner(at: date ?? dateGenerator.generate()) {
        case .mid(let survey):
            StudyPresenter.show(
                study: self,
                midStudySurvey: survey
            )
        case .completion:
            StudyPresenter.show(
                study: self,
                surveyType: .completion
            )
        case nil:
            return false
        }

        return true
    }

}
