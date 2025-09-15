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

open class Study: ObservableObject, HasAssignedGroups, GeneralStudy {
    
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
    
    public let studyInformation: StudyInformation
    public let uploadConfiguration: UploadConfiguration
    
    public var participationIsPossible: Bool
    public let studyIdentifier: String
    
    let introductorySurveyURL: URL?
    
    let introSurveyCompletionHandler: (([String: String], Study) -> Void)?
    let sharedAppGroupIdentifier: String?
    
    var additionalQueryItems: (SurveyType) -> [URLQueryItem] = { _ in [] }
    
    public lazy var store: StudyKeyValueStore = {
        StudyKeyValueStore(studyIdentifier: self.studyIdentifier, appGroup: self.sharedAppGroupIdentifier)
    }()
    
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
                
                let url = study.concludingSurveyURL.appendingQueryItem(name: "uuid", value: self.userIdentifier)
                
                if let assignedGroup = self.assignedGroup {
                    return url.appendingQueryItem(name: Keys.AssignedGroup, value: assignedGroup)
                }
                
                return url.appendingQueryItems(additionalQueryItems)
                
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
    
    open func currentStatus() async throws -> StudyStatus {
        
        if isActivelyRunning {
            return .successStyle(text: "Active")
        }
//        else if isDi {
//            return .mutedStyle(text: "Completed")
//        }
        else {
            return .mutedStyle(text: "Available")
        }
            
    }
    
    // MARK: - Views -
    
    open var invitationBannerView: AnyView {
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(self)
            .toAnyView()
    }
    
    // MARK: - UI Actions -
    
    public func showCompletionSurvey() {
        
        showView(SurveyWebView(surveyType: .completion).environmentObject(self))
        
    }
    
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
    
    public func terminateParticipationImmediately() {
        let terminationDate = Date()
        self.appendNewJSONObjects(newObjects: [
            [
                "terminationReason": "terminatedByUser",
                "timestamp": terminationDate.timeIntervalSince1970
            ]
        ])
        self.terminatedByUserDate = terminationDate
        self.uploadIfNecessary()
    }
    
    open func reset() throws {
        
        // Reset state variables (e.g. study identifier, all dates, etc.)
        self.store.deleteAllValues()
        
        // Delete all files
        try StudyFileManager.shared.deleteAllFiles(study: self, type: .working)
        try StudyFileManager.shared.deleteAllFiles(study: self, type: .upload)
        
    }
    
    // MARK: - Notifications -
    
    open func shouldHaveNotifications() -> Bool {
        return false
    }
    
    internal func prepareLocalNotifications(completion: @escaping () -> Void = {}) {
        
        if shouldHaveNotifications() {
            
            let alert = UIAlertController(
                title: NSLocalizedString("Post-Study-Questionnaire", bundle: Bundle.module, comment: ""),
                message: NSLocalizedString("We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.", bundle: Bundle.module, comment: ""),
                preferredStyle: .alert
            )
            
            let proceedAction = UIAlertAction(title: "Ok", style: .default) { _ in
                LocalPushController.shared.askUserForPushPermission { success in
                    
                    // todo: does it make sense to also register them when no push permission was given?
                    
                    self.registerNotifications()
                    
                    completion()
                    
                }
            }
            
            alert.addAction(proceedAction)
            
            UIViewController.topViewController()?.present(alert, animated: true)
            
        } else {
            completion()
        }
        
    }
    
    /// Place to register study related notifications. It is called after the user consented to take part in the study and if they
    open func registerNotifications() {
        
    }
    
    // MARK: - File Handling / Upload -
    
    public func studyDirectory(type: StudyDataDirectoryType = .working) -> URL {
        
        let fileManager = FileManager.default
        let documentDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let studyDirectoryURL = documentDirectoryURL
            .appendingPathComponent("OpenResearchKit/Studies", isDirectory: true)
            .appendingPathComponent(studyIdentifier, isDirectory: true)
            .appendingPathComponent(type.directoryName, isDirectory: true)
        
        // Ensure the directory exists
        do {
            try fileManager.createDirectory(
                at: studyDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            Logger.research.error("Failed to create study directory: \(error)")
        }
        
        return studyDirectoryURL
        
    }
    
    open func uploadIfNecessary() {
        
        guard let lastSuccessfulUploadDate = self.lastSuccessfulUploadDate else {
            if isActivelyRunning {
                self.uploadJSON()
            }
            return
        }
        
        if !isActivelyRunning {
            // todo
            // study is not running, dont upload anything
            return
        }
        
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadConfiguration.uploadFrequency {
            self.uploadJSON()
        }
        
    }
    
    // MARK: - Accessors -
    
    /// Indicates whether the study is currently active and eligible for data collection.
    ///
    /// For long-term studies, the study is active if the configured end date lies in the future.
    open var isActivelyRunning: Bool {
        
        // todo
        
        return false
        
    }
    
}

extension Study {
    
    internal var terminatedByUserDate: Date? {
        get {
            store.get(Keys.TerminatedByUserDate, type: Date.self)
        }
        
        set {
            store.update(Keys.TerminatedByUserDate, value: newValue)
            publishChangesOnMain()
        }
    }
    
    public var shouldDisplayIntroductorySurvey: Bool {
        
        if introductorySurveyURL == nil {
            return false
        }
        
        if !participationIsPossible {
            return false
        }
        
        return !hasUserGivenConsent && !isDismissedByUser
        
    }
    
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

// MARK: - Storage -

extension Study {
    
    private var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    private var fileName: String {
        "study-\(studyIdentifier)-\(userIdentifier).json"
    }
    
    private var jsonDataFilePath: URL {
        
        if let sharedAppGroupIdentifier {
            let fileManager = FileManager.default
            let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: sharedAppGroupIdentifier)!
            return directory.appendingPathComponent(fileName)
        }
        
        let readPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
        return readPath
    }
    
    internal var JSONFile: [[String: Any]] {
        if let jsonData = try? Data(contentsOf: jsonDataFilePath),
           let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let json = decoded as? [ [String: Any] ] {
            return json
        }
        
        return []
    }
    
    public func appendNewJSONObjects(newObjects: [ [String: JSONConvertible] ]) {
        if isActivelyRunning {
            // only add data if study is running: user has given consent and study has not yet ended
            var existingFile = self.JSONFile
            existingFile.append(contentsOf: newObjects)
            self.saveAndUploadIfNeccessary(jsonFile: existingFile)
        }
    }
    
    private func saveAndUploadIfNeccessary(jsonFile: [ [String: Any] ]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonFile, options: .prettyPrinted) {
            try? jsonData.write(to: jsonDataFilePath)
            self.uploadIfNecessary()
        }
    }
    
}

// MARK: - Upload -

extension Study {
    
    public var lastSuccessfulUploadDate: Date? {
        return store.get(Keys.LastSuccessfulUploadDate, type: Date.self)
    }
    
    public func updateUploadDate(newDate: Date = Date()) {
        
        store.update(Keys.LastSuccessfulUploadDate, value: newDate)
        publishChangesOnMain()
        
    }
    
    internal func uploadJSON() {
        
        StudyDataUploader.shared.uploadJSON(
            filePath: jsonDataFilePath,
            uploadConfiguration: uploadConfiguration,
            userIdentifier: userIdentifier,
            fileName: fileName
        ) { (result: Result<Void, any Error>) in
            
            switch result {
                    
                case .success(_):
                    DispatchQueue.main.async {
                        self.updateUploadDate()
                    }
                    
                case .failure(let error):
                    print(error)
                    
            }
            
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
