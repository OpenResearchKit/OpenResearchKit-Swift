//
//  HasIntroductorySurvey.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import SwiftUI

public protocol HasIntroductorySurvey: GeneralStudy {
    
    var invitationBannerView: AnyView { get }
    
    var shouldDisplayIntroductorySurvey: Bool { get }
    
    var introductorySurveyURL: URL? { get }
    
}
