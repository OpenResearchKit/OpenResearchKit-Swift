//
//  MidStudySurvey+Consistency.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 24.08.26.
//

extension Collection where Element == MidStudySurvey {
    
    func hasConsistentSurveyIdentities() -> Bool {
        
        var configurationByIdentifier: [String: MidStudySurvey] = [:]
        
        for survey in self {
            if let existingSurvey = configurationByIdentifier[survey.id] {
                guard existingSurvey.url == survey.url,
                      existingSurvey.showAfter.bitPattern == survey.showAfter.bitPattern,
                      existingSurvey.expiresAfter?.bitPattern
                        == survey.expiresAfter?.bitPattern else {
                    return false
                }
            } else {
                configurationByIdentifier[survey.id] = survey
            }
        }
        
        return true
        
    }
    
}
