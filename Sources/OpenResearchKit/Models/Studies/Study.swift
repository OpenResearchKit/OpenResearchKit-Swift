//
//  Study.swift
//
//
//  Created by Frederik Riedel on 18.11.22.
//

import Foundation
import UIKit
import SwiftUI
import OSLog

open class Study: ObservableObject, GeneralStudy, HasIntroductorySurvey, HasAssignedGroups, HasNotifications, UploadsStudyData {
    
    public let studyIdentifier: String
    public let studyInformation: StudyInformation
    public let uploadConfiguration: UploadConfiguration
    public let introductorySurveyURL: URL?
    public var participationIsPossible: Bool
    public let sharedAppGroupIdentifier: String?
    public var additionalQueryItems: (SurveyType) -> [URLQueryItem] = { _ in [] }
    public let introSurveyCompletionHandler: (([String: String], Study) -> Void)?
    
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        introductorySurveyURL: URL?,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] },
        introSurveyCompletionHandler: (([String: String], Study) -> Void)?
    ) {
        self.studyIdentifier = studyIdentifier
        self.studyInformation = studyInformation
        self.uploadConfiguration = uploadConfiguration
        
        
        self.introductorySurveyURL = introductorySurveyURL
        self.participationIsPossible = participationIsPossible
        self.sharedAppGroupIdentifier = sharedAppGroupIdentifier
        self.introSurveyCompletionHandler = introSurveyCompletionHandler
        self.additionalQueryItems = additionalQueryItems
        
        Study.allStudies.append(self)
    }
    
    public private(set) var userIdentifier: String {
        
        get {
            if let localUserIdentifier = store.get(Keys.LocalUserIdentifier, type: String.self) {
                return localUserIdentifier
            }
            
            let newLocalUserIdentifier = "\(studyIdentifier)-\(UUID().uuidString)"
            self.userIdentifier = newLocalUserIdentifier
            return newLocalUserIdentifier
        }
        
        set {
            store.update(Keys.LocalUserIdentifier, value: newValue)
            publishChangesOnMain()
        }
        
    }
    
    func surveyUrl(for surveyType: SurveyType) -> URL? {
        
        let additionalQueryItems: [URLQueryItem] = self.additionalQueryItems(surveyType)
        
        switch surveyType {
                
        case .introductory:
                
            return self.introductorySurveyURL?
                    .appendingQueryItem(name: "uuid", value: self.userIdentifier)
                    .appendingQueryItems(additionalQueryItems)
                
        case .completion:
                
            if let study = self as? LongTermStudy {
                
                let url = study.concludingSurveyURL?.appendingQueryItem(name: "uuid", value: self.userIdentifier)
                
                if let assignedGroup = self.assignedGroup {
                    return url?.appendingQueryItem(name: Keys.AssignedGroup, value: assignedGroup)
                }
                
                return url?.appendingQueryItems(additionalQueryItems)
                
            } else {
                return nil
            }
                
        case .mid:
            
            if let study = self as? (any HasMidSurvey) {
                return study.getMidSurvey().url
                    .appendingQueryItem(name: "uuid", value: self.userIdentifier)
                    .appendingQueryItems(additionalQueryItems)
            } else {
                return nil
            }
                
        }
    }
    
    open func currentDisplayStatus() async throws -> StudyStatus {
        
        if terminationBeforeCompletionDate != nil {
            return .errorStyle(text: "Terminated")
        }
        
        if participationIsPossible && !hasUserGivenConsent {
            return .mutedStyle(text: "Available")
        }
        
        return .mutedStyle(text: "Unknown")
            
    }
    
    // MARK: - Persistence -
    
    public lazy var store: StudyKeyValueStore = {
        StudyKeyValueStore(studyIdentifier: self.studyIdentifier, appGroup: self.sharedAppGroupIdentifier)
    }()
    
    // MARK: - Actions -
    
    public func saveUserConsentHasBeenGiven(
        consentTimestamp: Date,
        completion: @escaping () -> Void
    ) {
        
        store.update(Keys.UserConsentDate, value: consentTimestamp)
        
        publishChangesOnMain {
            self.prepareLocalNotifications {
                completion()
            }
        }
        
    }
    
    public func manuallyGiveUserConsent(
        timeStamp: Date = Date(),
        userId: String?,
        completion: @escaping () -> Void
    ) {
        self.saveUserConsentHasBeenGiven(consentTimestamp: timeStamp, completion: {
            if let userId {
                self.userIdentifier = userId
            }
            completion()
        })
        
    }
    
    open func reset() throws {
        
        // Reset state variables (e.g. study identifier, all dates, etc.)
        self.store.deleteAllValues()
        
        // Delete all files
        try StudyFileManager.shared.deleteAllFiles(study: self, type: .working)
        try StudyFileManager.shared.deleteAllFiles(study: self, type: .upload)
        
    }
    
    // MARK: - Callbacks
    
    public func didTerminateParticipation(terminationDate: Date) {
        self.appendNewJSONObjects(newObjects: [
            [
                "terminationReason": "terminatedByUser",
                "timestamp": terminationDate.timeIntervalSince1970
            ]
        ])
        self.uploadIfNecessary()
    }
    
    public func shouldUpload() -> Bool {
        
        guard let lastSuccessfulUploadDate else {
            return false
        }
        
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadConfiguration.uploadFrequency {
            return true
        }
        
        return false
        
    }
    
}

extension Study {
    
    public func publishChangesOnMain(completion: @escaping () -> Void = {}) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            completion()
        }
    }
    
    public func publishChangesOnMain() {
        self.publishChangesOnMain(completion: {})
    }
    
}

extension Study {
    
    static var allStudies = [Study]()
    
    public static var currentActiveStudy: Study? {
        
        allStudies.first { study in
            
            let consentedNotDismissed = study.hasUserGivenConsent && !study.isDismissedByUser
            
            if let study = study as? (any HasTerminationSurvey) {
                return !study.hasCompletedTerminationSurvey && consentedNotDismissed
            }
            
            return consentedNotDismissed
            
        }
        
    }
    
}

// MARK: - Keys -

extension Study {
    
    struct Keys {
        static let UserConsentDate = "userConsentDate"
        static let HasCompletedMidSurvey = "hasCompletedMidSurvey"
        static let IsDismissedByUser = "isDismissedByUser"
        static let TerminatedByUserDate = "terminatedByUserDate"
        static let HasCompletedTerminationSurvey = "hasCompletedTerminationSurvey"
        static let AssignedGroup = "assignedGroup"
        static let LastSuccessfulUploadDate = "lastSuccessfulUploadDate"
        static let LocalUserIdentifier = "localUserIdentifier"
    }
    
}
