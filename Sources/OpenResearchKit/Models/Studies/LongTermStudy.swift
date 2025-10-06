//
//  LongTermStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

open class LongTermStudy: Study, LongTerm, HasTerminationSurvey {
    
    public let duration: TimeInterval
    public let concludingSurveyURL: URL?
    
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        duration: TimeInterval,
        introductorySurveyURL: URL?,
        concludingSurveyURL: URL?,
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
    
    open override func currentDisplayStatus() async throws -> StudyStatus {
        
        if isActiveStudyPeriod {
            return .successStyle(text: "Running")
        }
        
        return try await super.currentDisplayStatus()
    }
    
    public override var isActive: Bool {
        
        if wasTerminatedBeforeCompletion {
            return false
        }
        
        let studyConsentedAndNotDismissed = hasUserGivenConsent && !isDismissedByUser
        let conclusionSurveyNotFinishedOrActiveStudyPeriod = !finishedConclusionSurveyOrNotNeeded || isActiveStudyPeriod
        let isActive = studyConsentedAndNotDismissed && conclusionSurveyNotFinishedOrActiveStudyPeriod
        
        return isActive
        
    }
    
    // MARK: - Data Handling -
    
    /// Appends data to the main study file if the user consented into taking part in the study and when the
    /// study period is actively running (from date of consent till the end of the configured duration.
    /// - Parameter newObjects: data to be added to the main study file
    open override func appendNewJSONObjects(newObjects: [[String : any JSONConvertible]]) {
        
        if isActiveStudyPeriod {
            super.appendNewJSONObjects(newObjects: newObjects)
        }
        
    }
    
    // MARK: - Uploading -
    
    open override func shouldUpload() -> Bool {
        
        guard let lastSuccessfulUploadDate = self.lastSuccessfulUploadDate else {
            if hasUserGivenConsent {
                return true
            }
            return false
        }
        
        if !isActiveStudyPeriod {
            if let actualStudyEndDate = self.actualStudyEndDate {
                // Study period is over (or participant terminated early), uploading remaining file one last time
                if lastSuccessfulUploadDate < actualStudyEndDate {
                    return true
                }
            }
            
            // The study period is over and the file was uploaded one last time
            return false
        }
        
        // Check if the last successful upload exceeds the configured uploading configuration
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadConfiguration.uploadFrequency {
            return true
        }
        
        return false
        
    }
    
    // MARK: - Notification Handling -
    
    open override func shouldHaveNotifications() -> Bool {
        return true
    }
    
    open override func registerNotifications() {
        
        super.registerNotifications()
        
        var pushDuration = self.duration
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
    
    // MARK: - Details -
    
    open override var shouldShowTerminationButton: Bool {
        return isActiveStudyPeriod
    }
    
    internal var finishedConclusionSurveyOrNotNeeded: Bool {
        
        let needsConclusionSurveyParticipation = self.concludingSurveyURL != nil
        
        if needsConclusionSurveyParticipation {
            return hasCompletedTerminationSurvey
        } else {
            return true
        }
        
    }
    
}
