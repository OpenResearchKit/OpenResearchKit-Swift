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
    
    public func completeIntroductionSurvey() {
        self.introductionSurveyCompletionDate = dateGenerator.generate()
        
        NotificationCenter.default.post(name: .completedIntroductionSurvey, object: self)
        
    }
    
}
