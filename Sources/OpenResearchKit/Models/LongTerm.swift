//
//  LongTerm.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

public protocol LongTerm: AnyObject, GeneralStudy {
    
    var duration: TimeInterval { get }
    
    /// Returns the end of the study if the user already started the study, `nil` otherwise.
    var studyEndDate: Date? { get }
    
}
