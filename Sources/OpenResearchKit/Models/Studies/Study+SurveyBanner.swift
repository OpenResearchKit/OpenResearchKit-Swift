//
//  Study+SurveyBanner.swift
//
//
//  Created by Lennart Fischer on 26.08.26.
//

import Foundation

enum StudySurveyBanner {
    case mid(MidStudySurvey)
    case completion
}

extension Study {

    func surveyBanner(at date: Date) -> StudySurveyBanner? {
        if let terminationSurveyStudy = self as? (any HasTerminationSurvey) {
            if terminationSurveyStudy.shouldDisplayTerminationSurvey(at: date) {
                return .completion
            }
        }

        if let midSurveyStudy = self as? (any HasMidSurvey),
           let survey = midSurveyStudy.midStudySurveyToDisplay(at: date) {
            return .mid(survey)
        }

        return nil
    }

}
