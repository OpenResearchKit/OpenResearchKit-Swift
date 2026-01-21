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
    
    static func show(study: Study, surveyType: SurveyType) {
        
        let surveyView = UIHostingController(
            rootView: SurveyWebView(
                surveyType: surveyType
            ).environmentObject(study)
        )
        
        surveyView.modalPresentationStyle = .fullScreen
        UIViewController.topViewController()?.present(surveyView, animated: true)
        
    }
    
}
