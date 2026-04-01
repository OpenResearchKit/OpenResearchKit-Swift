//
//  LongTerm.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

public protocol LongTerm: AnyObject, GeneralStudy {
    
    /// Intended duration of the treatment of the study.
    var duration: TimeInterval { get }
    
    /// Calculates the end of the study if the user already started the study, `nil` otherwise.
    /// - Note: If the user terminated the study earlier by immediately terminating the study, this will still be the initial end date.
    /// See `actualStudyEndDate` for retrieving the study end date respecting pre-completion terminations.
    var intendedStudyEndDate: Date? { get }
    
    /// Calculates the end of the study if the user already started the study, `nil` otherwise.
    /// If the study was terminated before exceeding the original `intendedStudyEndDate`, the `terminationBeforeCompletionDate` is returned.
    /// - Note: This respects pre-completion terminations and not only returns the `intendedStudyEndDate`.
    var actualStudyEndDate: Date? { get }
    
    /// Checks if the user consented into the study and the current date is between the consent date and the `intendedStudyEndDate` calculated based on the `duration`.
    /// If the study was terminated before the intented study end date, the study is not considered to be in active study period anymore.
    var isActiveStudyPeriod: Bool { get }
    
}

/// Default implementations of the protocols specifications.
extension LongTerm {
    
    public var intendedStudyEndDate: Date? {
        return userConsentDate?.addingTimeInterval(duration)
    }
    
    public var actualStudyEndDate: Date? {
        
        if let intendedStudyEndDate {
            return terminationBeforeCompletionDate ?? intendedStudyEndDate
        }
        
        return nil
        
    }
    
    public var isActiveStudyPeriod: Bool {
        
        if let studyEndDate = intendedStudyEndDate {
            let now = dateGenerator.generate()
            let studyEndInFuture = studyEndDate > now
            if studyEndInFuture && !wasTerminatedBeforeCompletion {
                return true
            }
        }
        
        return false
    }
    
}
