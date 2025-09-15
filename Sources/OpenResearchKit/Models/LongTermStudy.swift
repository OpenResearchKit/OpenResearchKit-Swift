//
//  LongTermStudy.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

open class LongTermStudy: Study, LongTerm {
    
    public var duration: TimeInterval
    
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        duration: TimeInterval,
        introductorySurveyURL: URL?,
        midStudySurvey: MidStudySurvey? = nil,
        concludingSurveyURL: URL?,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] },
        introSurveyCompletionHandler: (([String : String], Study) -> Void)?
    ) {
        self.duration = duration
        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            introductorySurveyURL: introductorySurveyURL,
            midStudySurvey: midStudySurvey,
            concludingSurveyURL: concludingSurveyURL,
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
    
}
