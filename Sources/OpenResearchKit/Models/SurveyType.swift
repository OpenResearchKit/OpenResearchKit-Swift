//
//  SurveyType.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//

public enum SurveyType: CaseIterable {
    
    case introductory, mid, completion
    
}

extension SurveyType {

    var canDismissStudyFromBanner: Bool {
        self == .introductory
    }

}
