//
//  HasTerminationSurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation
import SwiftUI

public protocol HasTerminationSurvey: AnyObject, LongTerm, GeneralStudy {
    
    var hasCompletedTerminationSurvey: Bool { get set }
    
    var shouldDisplayTerminationSurvey: Bool { get }
    
    var terminationBannerView: AnyView { get }
    
    func showCompletionSurvey()
    
}

extension HasTerminationSurvey {
    
    public var hasCompletedTerminationSurvey: Bool {
        get {
            return store.get(Study.Keys.HasCompletedTerminationSurvey, type: Bool.self) ?? false
        }
        
        set {
            
            store.update(Study.Keys.HasCompletedTerminationSurvey, value: newValue)
            publishChangesOnMain {
                if newValue {
                    LocalPushController.clearNotifications(with: "survey-completion-notification")
                    LocalPushController.clearNotifications(with: "survey-completion-notification-reminder")
                }
            }
            
        }
    }
    
    public var shouldDisplayTerminationSurvey: Bool {
        if let intendedStudyEndDate {
            return !intendedStudyEndDate.isInFuture && !hasCompletedTerminationSurvey && !isDismissedByUser
        }
        return false
    }
    
    public var terminationBannerView: AnyView {
        StudyBannerInvitation(surveyType: .completion)
            .environmentObject(self)
            .toAnyView()
    }
    
    public func showCompletionSurvey() {
        
        showView(SurveyWebView(surveyType: .completion).environmentObject(self))
        
    }
    
}
