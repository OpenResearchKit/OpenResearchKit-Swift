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
    
    var hasCompletedMidSurvey: Bool { get }
    
    /// A mid survey should be displayed if the user has consented into participating in the study and as soon
    /// as the `showAfterDate` interval of the study has elapsed.
    var shouldDisplayMidSurvey: Bool { get }
    
    func showMidStudySurvey()
    
}

extension HasMidSurvey {
    
    public private(set) var hasCompletedMidSurvey: Bool {
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
            let now = dateGenerator.generate()
            
            if showAfterDate < now && !hasCompletedMidSurvey {
                return true
            }
        }
        
        return false
        
    }
    
    public func showMidStudySurvey() {
        
        self.showView(SurveyWebView(surveyType: .mid).environmentObject(self))
        
    }
    
    public func completeMidSurvey() {
        
        self.hasCompletedMidSurvey = true
        
    }
    
}
