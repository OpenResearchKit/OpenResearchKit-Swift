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
    
    /// Workaround as we need to have an active study at all times.
    public static let emptyPlaceholderStudyIdentifier = "empty"
    
    public let studyIdentifier: String
    public let studyInformation: StudyInformation
    public var uploadConfiguration: UploadConfiguration
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
    
    open func currentDisplayStatus() async throws -> StudyStatus {
        
        if isCompleted {
            return .successStyle(text: "Completed")
        }
        
        if terminationBeforeCompletionDate != nil {
            return .errorStyle(text: "Terminated")
        }
        
        if await isEligible() && !hasUserGivenConsent {
            return .mutedStyle(text: "Available")
        }
        
        return .mutedStyle(text: "Unknown")
        
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
    
    public var isActive: Bool {
        
        let consentedNotDismissed = self.hasUserGivenConsent // && !self.isDismissedByUser
        
        return consentedNotDismissed
        
    }
    
    public var isCompleted: Bool {
        get {
            return completionDate != nil
        }
        set {
            completionDate = dateGenerator.generate()
        }
    }
    
    internal var completionDate: Date? {
        get {
            store.get(Keys.CompletionDate, type: Date.self)
        }
        set {
            store.update(Keys.CompletionDate, value: newValue)
        }
    }
    
    // MARK: - Eligibility -
    
    @MainActor
    open func isEligible() -> Bool {
        return participationIsPossible
    }
    
    // MARK: - Persistence -
    
    public lazy var store: StudyKeyValueStore = {
        StudyKeyValueStore(studyIdentifier: self.studyIdentifier, appGroup: self.sharedAppGroupIdentifier)
    }()
    
    // MARK: - Actions -
    
    public func saveUserConsentHasBeenGiven(
        consentTimestamp: Date? = nil,
        completion: @escaping () -> Void
    ) {
        
        let timestamp = consentTimestamp ?? dateGenerator.generate()
        
        store.update(Keys.UserConsentDate, value: timestamp)
        
        publishChangesOnMain {
            self.prepareLocalNotifications {
                completion()
            }
        }
        
    }
    
    public func manuallyGiveUserConsent(
        timeStamp: Date? = nil,
        userId: String?,
        completion: @escaping () -> Void
    ) {
        
        let consentTimestamp = timeStamp ?? dateGenerator.generate()
        
        self.saveUserConsentHasBeenGiven(consentTimestamp: consentTimestamp, completion: {
            if let userId {
                self.userIdentifier = userId
            }
            completion()
        })
        
    }
    
    open func reset() throws {
        
        // Reset state variables (e.g. study identifier, all dates, etc.)
        self.store.deleteAllValues()
        
        try self.resetLocalJSONFile()
        
        // Delete all files
        try StudyFileManager.shared.deleteAllFiles(study: self, type: .working)
        try StudyFileManager.shared.deleteAllFiles(study: self, type: .upload)
        
    }
    
    open func handleIntroductionSurveyResults(consented: Bool, parameters: [String: String], dismissView: @escaping () -> Void) {
        
        if consented {
            
            if let group = parameters["assignedGroup"] {
                self.assignedGroup = group
            } else if let group = parameters["groupid"] {
                self.assignedGroup = group
            }
            
            self.saveUserConsentHasBeenGiven() {
                
                self.didFinishSurveyIntroPreCompletionHandler()
                
                dismissView()
                
                self.introSurveyCompletionHandler?(
                    parameters,
                    self
                )
                
                self.didFinishSurveyPostCompletionHandler()
                
            }
            
        } else {
            self.isDismissedByUser = true
            dismissView()
        }
        
    }
    
    // MARK: - Callbacks -
    
    open func didTerminateParticipation(terminationDate: Date) {
        self.appendNewJSONObjects(newObjects: [
            [
                "terminationReason": "terminatedByUser",
                "timestamp": terminationDate.timeIntervalSince1970
            ]
        ])
        self.uploadIfNecessary()
    }
    
    open func didFinishSurveyIntroPreCompletionHandler() {
        
    }
    
    open func didFinishSurveyPostCompletionHandler() {
        
    }
    
    open func didUploadStudyFolder() async throws {
        
    }
    
    // MARK: - Helpers -
    
    public internal(set) var dateGenerator: any DateGenerator = DefaultDateGenerator()
    
    // MARK: - HasIntroductionSurvey -
    
    open var invitationBannerView: AnyView {
        
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(self)
            .toAnyView()
        
    }
    
    open var shouldDisplayIntroductorySurvey: Bool {
        
        if introductorySurveyURL == nil {
            return false
        }
        
        if studyIdentifier == Self.emptyPlaceholderStudyIdentifier {
            return false
        }
        
        return !completedIntroductionSurvey && !isDismissedByUser
        
    }

    // MARK: -
    
    /// Prepares and sets up local notifications for the study after user consent.
    ///
    /// This method is automatically called when a user gives consent to participate in a study.
    /// It handles the complete notification setup flow including:
    /// 1. Checking if the study requires notifications via `shouldHaveNotifications()`
    /// 2. Presenting a user-friendly alert explaining why notifications are needed
    /// 3. Requesting push notification permissions from the system
    /// 4. Calling `registerNotifications()` to set up study-specific notifications
    ///
    /// ## Notification Flow
    ///
    /// The method follows this sequence:
    /// - If `shouldHaveNotifications()` returns `false`, the completion handler is called immediately
    /// - If notifications are required, displays an alert to inform the user about post-study questionnaires
    /// - Upon user confirmation, requests system notification permissions
    /// - Calls `registerNotifications()` regardless of permission grant status
    /// - Executes the completion handler when the flow is complete
    ///
    /// ## Alert Content
    ///
    /// The alert displays localized content:
    /// - **Title**: "Post-Study-Questionnaire" (localized)
    /// - **Message**: "We'll send you a push notification when the study is concluded to fill out the post-questionnaire." (localized)
    /// - **Action**: "Ok" button to proceed with permission request
    ///
    /// ## Unit Testing Considerations
    ///
    /// When running unit tests (`Bundle.main.isRunningUnitTests` is `true`), the completion
    /// handler is called immediately to prevent UI interactions during automated testing.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // Called automatically during consent process
    /// study.saveUserConsentHasBeenGiven(consentTimestamp: Date()) {
    ///     // Notifications are now prepared
    ///     print("User consent saved and notifications prepared")
    /// }
    /// ```
    ///
    /// ## Implementation Notes
    ///
    /// - Permission denial doesn't prevent `registerNotifications()` from being called
    /// - The alert is presented on the topmost view controller in the hierarchy
    /// - All UI operations are performed on the main thread
    ///
    /// - Parameter completion: A closure executed when the notification preparation is complete.
    ///   Called immediately if notifications are disabled, or after the permission flow when enabled.
    ///   Defaults to an empty closure if not provided.
    ///
    /// - Important: This method should not be called directly. It's automatically invoked
    ///   as part of the user consent process in `saveUserConsentHasBeenGiven(consentTimestamp:completion:)`.
    ///
    /// - Note: The actual notification scheduling should be implemented in the `registerNotifications()`
    ///   method of conforming types.
    ///
    /// - SeeAlso:
    ///   - `shouldHaveNotifications()` for controlling whether notifications are used
    ///   - `registerNotifications()` for implementing study-specific notification scheduling
    ///   - `LocalPushController.shared.askUserForPushPermission(completion:)` for the permission request implementation
    internal func prepareLocalNotifications(completion: @escaping () -> Void = {}) {
        
        if shouldHaveNotifications() {
            
            let alert = UIAlertController(
                title: NSLocalizedString(
                    "Post-Study-Questionnaire", bundle: Bundle.module, comment: ""),
                message: NSLocalizedString(
                    "We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.",
                    bundle: Bundle.module, comment: ""),
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
            
            if Bundle.main.isRunningUnitTests {
                completion()
            }
            
        } else {
            completion()
        }
        
    }
    
    open func shouldHaveNotifications() -> Bool {
        return false
    }
    
    open func registerNotifications() {
        
    }
    
    // MARK: - UploadsStudyData -
    
    public func studyDirectory(type: StudyDataDirectoryType = .working) -> URL {
        
        let fileManager = FileManager.default
        let studyDirectoryURL = baseDirectory
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
    
    public func appendNewJSONObjects(newObjects: [[String: JSONConvertible]]) {
        
        if hasUserGivenConsent {
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
    
    internal func resetLocalJSONFile() throws {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: jsonDataFilePath.path) {
            try fileManager.removeItem(at: jsonDataFilePath)
        }
    }
    
    internal var JSONFile: [[String: Any]] {
        if let jsonData = try? Data(contentsOf: jsonDataFilePath),
           let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let json = decoded as? [ [String: Any] ] {
            return json
        }
        
        return []
    }
    
    private var mainFileName: String {
        "study-\(studyIdentifier)-\(userIdentifier).json"
    }
    
    private var jsonDataFilePath: URL {
        return baseDirectory.appendingPathComponent(mainFileName)
    }
    
    internal var baseDirectory: URL {
        
        if let sharedAppGroupIdentifier {
            let fileManager = FileManager.default
            return fileManager.containerURL(forSecurityApplicationGroupIdentifier: sharedAppGroupIdentifier)!
        }
        
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    }
    
    // MARK: - Upload
    
    open func shouldUpload() -> Bool {
        
        // If the participant has not consented into the study, we don't allow uploads.
        if !hasUserGivenConsent {
            return false
        }
        
        // If the data was never uploaded before, the data should be uploaded.
        guard let lastSuccessfulUploadDate else {
            return true
        }
        
        // If the study is still treated active and the uploadConfiguration instructs us to upload, we upload.
        if isActive {
            return uploadConfiguration.isUploadDue(lastUpload: lastSuccessfulUploadDate)
        }
        
        return false
        
    }
    
    open func uploadIfNecessary() {
        
        if shouldUpload() {
            self.uploadJSON()
        }
        
    }
    
    public var lastSuccessfulUploadDate: Date? {
        return store.get(Study.Keys.LastSuccessfulUploadDate, type: Date.self)
    }
    
    internal func uploadJSON() {
        
        StudyDataUploader.shared.uploadJSON(
            filePath: jsonDataFilePath,
            uploadConfiguration: uploadConfiguration,
            userIdentifier: userIdentifier,
            fileName: mainFileName
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
    
    internal func updateUploadDate(newDate: Date? = nil) {
        
        let date = newDate ?? dateGenerator.generate()
        
        store.update(Study.Keys.LastSuccessfulUploadDate, value: date)
        publishChangesOnMain()
        
    }
    
    public func copyMainJSONToUpload() throws {
        
        let fileManager = FileManager.default
        let destination = self.studyDirectory(type: .upload).appendingPathComponent(mainFileName)
        
        // Check that the main json file already exists
        if fileManager.fileExists(atPath: jsonDataFilePath.path) {
            
            // If a file with the same name already exists in the folder, we delete it first
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            
            // Copy the file over
            try fileManager.copyItem(at: jsonDataFilePath, to: destination)
            
        } else {
            Logger.research.warning("The main json files does not exist currently. Maybe you forgot giving the user consent before trying to copy?")
        }
        
    }
    
    // MARK: - HasTerminationSurvey
    
    open var terminationBannerView: AnyView {
        StudyBannerInvitation(surveyType: .completion)
            .environmentObject(self)
            .toAnyView()
    }
    
    // MARK: - Detail View -
    
    /// Determines if the termination button should be shown in the detail screen of the study in the settings.
    /// Mostly relevant for long-term studies affecting the user experience.
    open var shouldShowTerminationButton: Bool {
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
    
    public static var allStudies = [Study]()
    
    public static var currentActiveStudy: Study? {
        
        allStudies
            .first { study in
                return study.isActive
            }
        
    }
    
    @MainActor
    public static func filterRecommended(studies: [Study]) -> [Study] {
        
        var result: [Study] = []
        
        for study in studies {
            if study.isDismissedByUser { continue }
            if study.isCompleted { continue }
            if study.studyIdentifier == Study.emptyPlaceholderStudyIdentifier { continue }
            if study.isEligible() {
                result.append(study)
            }
        }
        
        return result
            
    }
    
    public static func filterCompleted(studies: [Study]) -> [Study] {
        
        return studies
            .filter {
                $0.isCompleted || $0.wasTerminatedBeforeCompletion
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
        static let CompletionDate = "completionDate"
        static let IntroSurveyCompletionDate = "introSurveyCompletionDate"
    }
    
}
