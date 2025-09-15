//
//  HasIntroductorySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import SwiftUI

public protocol HasIntroductorySurvey: GeneralStudy {
    
    var invitationBannerView: AnyView { get }
    
    var shouldDisplayIntroductorySurvey: Bool { get }
    
    var introductorySurveyURL: URL? { get }
    
}

public extension HasIntroductorySurvey {
    
    var invitationBannerView: AnyView {
        
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(self)
            .toAnyView()
        
    }
    
    var shouldDisplayIntroductorySurvey: Bool {
        
        if introductorySurveyURL == nil {
            return false
        }
        
        if !participationIsPossible {
            return false
        }
        
        return !hasUserGivenConsent && !isDismissedByUser
        
    }
    
}
