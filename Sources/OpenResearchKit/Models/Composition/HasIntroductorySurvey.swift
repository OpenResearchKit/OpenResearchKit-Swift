//
//  HasIntroductorySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import SwiftUI

public protocol HasIntroductorySurvey: GeneralStudy {
    
    var invitationBannerView: AnyView { get }
    
    /// Determines if the introductory survey view (banner / teaser) should be shown.
    var shouldDisplayIntroductorySurvey: Bool { get }
    
    var introductorySurveyURL: URL? { get }
    
    var introductionSurveyCompletionDate: Date? { get }
    
    func completeIntroductionSurvey()

    /// Presents the introductory survey directly. This is useful when the host
    /// app resolves a URL scheme or deep link to this study.
    func showIntroSurvey()
    
}

extension HasIntroductorySurvey {
    
    public private(set) var introductionSurveyCompletionDate: Date? {
        get {
            store.get(Study.Keys.IntroSurveyCompletionDate, type: Date.self)
        }
        set {
            store.update(Study.Keys.IntroSurveyCompletionDate, value: newValue)
        }
    }
    
    public var completedIntroductionSurvey: Bool {
        return introductionSurveyCompletionDate != nil
    }

    public func showIntroSurvey() {
        if let study = self as? Study {
            showView(SurveyWebView(surveyType: .introductory, study: study))
        }
    }
    
    public func completeIntroductionSurvey() {
        self.introductionSurveyCompletionDate = dateGenerator.generate()
        
        NotificationCenter.default.post(name: .completedIntroductionSurvey, object: self)
        
    }
    
}
