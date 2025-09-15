//
//  DataDonationStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

open class DataDonationStudy: Study {
    
    /// For data donation studies (which have no fixed duration), the study is considered active
    /// if the user has given consent and has not explicitly terminated participation.
    public override var isActivelyRunning: Bool {
        
        if hasUserGivenConsent && self.terminatedByUserDate == nil {
            return true
        }
        
        return false
        
    }
    
}
