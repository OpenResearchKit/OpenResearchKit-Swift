//
//  DataDonationStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

open class DataDonationStudy: Study {
    
    /// For data donation studies (which have no fixed duration), the study is considered active
    /// if the user has given consent and has not explicitly terminated participation or completed or dismissed.
    public override var isActive: Bool {
        
        let terminatedOrCompletedOrDismissed = wasTerminatedBeforeCompletion || isCompleted || isDismissedByUser
        
        if hasUserGivenConsent && !terminatedOrCompletedOrDismissed {
            return true
        }
        
        return false
        
    }
    
    // MARK: - Callbacks -
    
    public override func didFinishSurveyPostCompletionHandler() {
        super.didFinishSurveyPostCompletionHandler()
        
        self.isCompleted = true
    }
    
}

