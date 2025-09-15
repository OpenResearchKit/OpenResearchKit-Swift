//
//  LongTermStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

open class LongTermStudy: Study, LongTerm {
    
    public let duration: TimeInterval
    public let concludingSurveyURL: URL
    
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        duration: TimeInterval,
        introductorySurveyURL: URL,
        concludingSurveyURL: URL,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] },
        introSurveyCompletionHandler: (([String : String], Study) -> Void)?
    ) {
        self.duration = duration
        self.concludingSurveyURL = concludingSurveyURL
        
        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            introductorySurveyURL: introductorySurveyURL,
            participationIsPossible: participationIsPossible,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier,
            additionalQueryItems: additionalQueryItems,
            introSurveyCompletionHandler: introSurveyCompletionHandler
        )
    }
    
    open override var isActivelyRunning: Bool {
        
        if let studyEndDate = studyEndDate {
            if studyEndDate.isInFuture {
                return true
            }
        }
        
        return false
    }
    
    open override func uploadIfNecessary() {
        
        guard let lastSuccessfulUploadDate = self.lastSuccessfulUploadDate else {
            if isActivelyRunning {
                self.uploadJSON()
            }
            return
        }
        
        if !isActivelyRunning {
            if let studyEndDate = self.studyEndDate {
                // study terminated, uploading remaining file
                if lastSuccessfulUploadDate < studyEndDate {
                    self.uploadJSON()
                    return
                }
            }
            
            // study is not running, dont upload anything
            return
        }
        
        
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadConfiguration.uploadFrequency {
            self.uploadJSON()
        }
        
    }
    
    public var studyEndDate: Date? {
        return userConsentDate?.addingTimeInterval(duration)
    }
    
    // MARK: - Notification Handling -
    
    open override func shouldHaveNotifications() -> Bool {
        return true
    }
    
    open override func registerNotifications() {
        
        super.registerNotifications()
        
        var pushDuration = self.studyInformation.duration ?? 0
#if DEBUG
        pushDuration = 10
#endif
        
        // Survey Completion Reminder after Study duration has ellapsed
        LocalPushController.shared.sendLocalNotification(
            in: pushDuration,
            title: NSLocalizedString("Concluding the study", bundle: Bundle.module, comment: ""),
            subtitle: NSLocalizedString("Thanks for participating. Please fill out one last survey.", bundle: Bundle.module, comment: ""),
            body: NSLocalizedString("It only takes 3 minutes to complete this survey.", bundle: Bundle.module, comment: ""),
            identifier: "survey-completion-notification"
        )
        
        // Additional Survey Completion Reminder (after 3 days)
        LocalPushController.shared.sendLocalNotification(
            in: pushDuration + 3 * 24 * 60 * 60,
            title: "Survey Completion Still Pending",
            subtitle: "Thanks for participating. You can complete the exit survey at any time.",
            body: "It only takes about 3 minutes.",
            identifier: "survey-completion-notification-reminder"
        )
        
    }
    
}
