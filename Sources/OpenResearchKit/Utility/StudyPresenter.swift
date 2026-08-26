//
//  StudyPresenter.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 21.01.26.
//

import UIKit
import SwiftUI

/// The `StudyPresenter` enum serves as a non-instantiatable static helper to present a `Study` anywhere in full screen as the top-most view controller.
public enum StudyPresenter {
    
}

public extension StudyPresenter {

    /// Presents the selected survey for a study.
    static func show(study: Study, surveyType: SurveyType) {
        present(
            SurveyWebView(
                surveyType: surveyType,
                study: study
            )
        )
    }

    internal static func show(
        study: Study,
        midStudySurvey: MidStudySurvey
    ) {
        present(
            SurveyWebView(
                study: study,
                midStudySurvey: midStudySurvey
            )
        )
    }

    private static func present(_ survey: SurveyWebView) {
        let surveyView = UIHostingController(rootView: survey)
        surveyView.modalPresentationStyle = .fullScreen
        UIViewController.topViewController()?.present(surveyView, animated: true)
    }

}
