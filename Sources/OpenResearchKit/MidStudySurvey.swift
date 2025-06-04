//
//  MidStudySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//


import Foundation

public struct MidStudySurvey {
    
    public init(showAfter: TimeInterval, url: URL) {
        self.showAfter = showAfter
        self.url = url
    }
    
    let showAfter: TimeInterval
    let url: URL
    
}
