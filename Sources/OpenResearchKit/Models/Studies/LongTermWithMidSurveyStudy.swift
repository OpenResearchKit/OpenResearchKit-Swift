//
//  LongTermWithMidSurveyStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import SwiftUI

open class LongTermWithMidSurveyStudy: LongTermStudy, HasMidSurvey {
    
    let midSurvey: MidStudySurvey
    
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        duration: TimeInterval,
        introductorySurveyURL: URL,
        midStudySurvey: MidStudySurvey,
        concludingSurveyURL: URL,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        studyFileManager: StudyFileManager = .shared,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] }
    ) {
        self.midSurvey = midStudySurvey
        
        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurveyURL,
            concludingSurveyURL: concludingSurveyURL,
            participationIsPossible: participationIsPossible,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier,
            studyFileManager: studyFileManager,
            additionalQueryItems: additionalQueryItems
        )
    }
    
    open override func registerNotifications() {
        super.registerNotifications()
        
        let midStudySurvey = getMidSurvey()
        
        LocalPushController.shared.sendLocalNotification(
            in: midStudySurvey.showAfter,
            title: NSLocalizedString("Mid-Study Survey", bundle: Bundle.module, comment: ""),
            subtitle: NSLocalizedString("Please fill out our short mid-study survey.", bundle: Bundle.module, comment: ""),
            body: NSLocalizedString("It only takes 3 minutes to complete this survey.", bundle: Bundle.module, comment: ""),
            identifier: "mid-study-survey-notification"
        )
        
        LocalPushController.shared.sendLocalNotification(
            in: midStudySurvey.showAfter + 3 * 24 * 60 * 60,
            title: "Survey Completion Still Pending",
            subtitle: "Reminder: Please fill out our short mid-study survey.",
            body: "It only takes about 3 minutes.",
            identifier: "mid-study-survey-notification-reminder"
        )
        
    }
    
    public override var isActive: Bool {
        
        return super.isActive && !hasCompletedMidSurvey
        
    }
    
    // MARK: - HasMidSurvey -
    
    func getMidSurvey() -> MidStudySurvey {
        return self.midSurvey
    }
    
    var midSurveyBannerView: AnyView {
        StudyBannerInvitation(study: self, surveyType: .mid)
            .toAnyView()
    }
    
}
