//
//  HasMidSurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import SwiftUI

protocol HasMidSurvey: AnyObject, GeneralStudy {
    
    func getMidSurvey() -> MidStudySurvey
    
    var midSurveyBannerView: AnyView { get }
    
    var hasCompletedMidSurvey: Bool { get set }
    
    var shouldDisplayMidSurvey: Bool { get }
    
    func showMidStudySurvey()
    
}

extension HasMidSurvey {
    
    public var hasCompletedMidSurvey: Bool {
        get {
            return store.get(Study.Keys.HasCompletedMidSurvey, type: Bool.self) ?? false
        }
        
        set {
            store.update(Study.Keys.HasCompletedMidSurvey, value: newValue)
            publishChangesOnMain {
                if newValue {
                    LocalPushController.clearNotifications(with: "mid-study-survey-notification")
                    LocalPushController.clearNotifications(with: "mid-study-survey-notification-reminder")
                }
            }
        }
    }
    
    public var shouldDisplayMidSurvey: Bool {
        
        let midSurvey = getMidSurvey()
        
        if let userConsentDate {
            let showAfterDate = userConsentDate.addingTimeInterval(midSurvey.showAfter)
            if !showAfterDate.isInFuture && !hasCompletedMidSurvey {
                return true
            }
        }
        
        return false
        
    }
    
    public func showMidStudySurvey() {
        
        self.showView(SurveyWebView(surveyType: .mid).environmentObject(self))
        
    }
    
}
