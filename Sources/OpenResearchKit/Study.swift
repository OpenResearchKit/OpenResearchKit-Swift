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

open class Study: ObservableObject {
    
    static var allStudies = [Study]()
    
    public static var currentActiveStudy: Study? {
        allStudies.first { study in
            study.hasUserGivenConsent && !study.hasCompletedTerminationSurvey && !study.isDismissedByUser
        }
    }
    
    public init(
        studyIdentifier: String,
        studyInformation: StudyInformation,
        uploadConfiguration: UploadConfiguration,
        introductorySurveyURL: URL?,
        midStudySurvey: MidStudySurvey? = nil,
        concludingSurveyURL: URL?,
        participationIsPossible: Bool = true,
        sharedAppGroupIdentifier: String? = nil,
        isDataDonationStudy: Bool = false,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] },
        introSurveyCompletionHandler: (([String: String], Study) -> Void)?
    ) {
        self.studyIdentifier = studyIdentifier
        self.studyInformation = studyInformation
        self.uploadConfiguration = uploadConfiguration
        
        
        self.introductorySurveyURL = introductorySurveyURL
        self.midStudySurvey = midStudySurvey
        self.concludingSurveyURL = concludingSurveyURL
        self.participationIsPossible = participationIsPossible
        self.sharedAppGroupIdentifier = sharedAppGroupIdentifier
        self.introSurveyCompletionHandler = introSurveyCompletionHandler
        self.isDataDonationStudy = isDataDonationStudy
        self.additionalQueryItems = additionalQueryItems
        
        Study.allStudies.append(self)
    }
    
    public let studyInformation: StudyInformation
    public let uploadConfiguration: UploadConfiguration
    
    public var participationIsPossible: Bool
    public let studyIdentifier: String
    
    let introductorySurveyURL: URL?
    let midStudySurvey: MidStudySurvey?
    let concludingSurveyURL: URL?
    
    let introSurveyCompletionHandler: (([String: String], Study) -> Void)?
    let sharedAppGroupIdentifier: String?
    let isDataDonationStudy: Bool
    
    var additionalQueryItems: (SurveyType) -> [URLQueryItem] = { _ in [] }
    
    public private(set) var userIdentifier: String {
        
        get {
            let studyUserDefaults = self.studyUserDefaults
            
            if let localUserIdentifier = studyUserDefaults["localUserIdentifier"] as? String {
                return localUserIdentifier
            }
            
            let newLocalUserIdentifier = "\(studyIdentifier)-\(UUID().uuidString)"
            self.userIdentifier = newLocalUserIdentifier
            return newLocalUserIdentifier
        }
        
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["localUserIdentifier"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
    }
    
    public var studyUserDefaults: [String: Any] {
        OpenResearchKit.researchKitDefaults(appGroup: self.sharedAppGroupIdentifier)[self.studyIdentifier] ?? [:]
    }
    
    func save(studyUserDefaults: [String: Any]) {
        OpenResearchKit.saveStudyDefaults(defaults: studyUserDefaults, appGroup: self.sharedAppGroupIdentifier, studyIdentifier: self.studyIdentifier)
    }
    
    func surveyUrl(for surveyType: SurveyType) -> URL? {
        
        let additionalQueryItems: [URLQueryItem] = self.additionalQueryItems(surveyType)
        
        switch surveyType {
                
        case .introductory:
                
            return self.introductorySurveyURL?
                    .appendingQueryItem(name: "uuid", value: self.userIdentifier)
                    .appendingQueryItems(additionalQueryItems)
                
        case .completion:
                
            let url = self.concludingSurveyURL?.appendingQueryItem(name: "uuid", value: self.userIdentifier)
            
            if let assignedGroup = self.studyUserDefaults["assignedGroup"] as? String {
                return url?.appendingQueryItem(name: "assignedGroup", value: assignedGroup)
            }
            
            return url?.appendingQueryItems(additionalQueryItems)
                
        case .mid:
            
            return self.midStudySurvey?.url
                    .appendingQueryItem(name: "uuid", value: self.userIdentifier)
                    .appendingQueryItems(additionalQueryItems)
                
        }
    }
    
    // MARK: - Views -
    
    open var invitationBannerView: AnyView {
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(self)
            .toAnyView()
    }
    
    public var terminationBannerView: some View {
        StudyBannerInvitation(surveyType: .completion)
            .environmentObject(self)
    }
    
    public var midSurveyBannerView: some View {
        StudyBannerInvitation(surveyType: .mid)
            .environmentObject(self)
    }
    
    public var detailInfosView: some View {
        StudyActiveDetailInfos()
            .environmentObject(self)
    }
    
    // MARK: - Actions -
    
    public func showCompletionSurvey() {
        let surveyView = SurveyWebView(surveyType: .completion).environmentObject(self)
        let hostingCOntroller = UIHostingController(rootView: surveyView)
        hostingCOntroller.modalPresentationStyle = .fullScreen
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: {
            UIViewController.topViewController()?.present(hostingCOntroller, animated: true)
        })
    }
    
    public func showMidStudySurvey() {
        guard let midStudySurvey else {
            return
        }
        
        let surveyView = SurveyWebView(surveyType: .mid).environmentObject(self)
        let hostingController = UIHostingController(rootView: surveyView)
        hostingController.modalPresentationStyle = .fullScreen
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: {
            UIViewController.topViewController()?.present(hostingController, animated: true)
        })
    }
    
    public func saveUserConsentHasBeenGiven(
        consentTimestamp: Date,
        completion: @escaping () -> Void
    ) {
        var studyUserDefaults = self.studyUserDefaults
        studyUserDefaults["userConsentDate"] = consentTimestamp
        self.save(studyUserDefaults: studyUserDefaults)
        DispatchQueue.main.async {
            self.objectWillChange.send()
            
            if self.midStudySurvey != nil || self.concludingSurveyURL != nil {
                let alert = UIAlertController(
                    title: NSLocalizedString("Post-Study-Questionnaire", bundle: Bundle.module, comment: ""),
                    message: NSLocalizedString("We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.", bundle: Bundle.module, comment: ""),
                    preferredStyle: .alert
                )
                
                let proceedAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    LocalPushController.shared.askUserForPushPermission { success in
                        var pushDuration = self.studyInformation.duration ?? 0
#if DEBUG
                        pushDuration = 10
#endif
                        
                        if let midStudySurvey = self.midStudySurvey {
                            LocalPushController.shared.sendLocalNotification(
                                in: midStudySurvey.showAfter,
                                title: NSLocalizedString("Mid-Study Survey", bundle: Bundle.module, comment: ""),
                                subtitle: NSLocalizedString("Please fill out our short mid-study survey.", bundle: Bundle.module, comment: ""),
                                body: NSLocalizedString("It only takes 3 minutes to complete this survey.", bundle: Bundle.module, comment: ""),
                                identifier: "mid-study-survey-notification"
                            )
                            
                            LocalPushController.shared.sendLocalNotification(in: midStudySurvey.showAfter + 3 * 24 * 60 * 60, title: "Survey Completion Still Pending", subtitle: "Reminder: Please fill out our short mid-study survey.", body: "It only takes about 3 minutes.", identifier: "mid-study-survey-notification-reminder")
                        }
                        
                        
                        
                        LocalPushController.shared.sendLocalNotification(
                            in: pushDuration,
                            title: NSLocalizedString("Concluding the study", bundle: Bundle.module, comment: ""),
                            subtitle: NSLocalizedString("Thanks for participating. Please fill out one last survey.", bundle: Bundle.module, comment: ""),
                            body: NSLocalizedString("It only takes 3 minutes to complete this survey.", bundle: Bundle.module, comment: ""),
                            identifier: "survey-completion-notification"
                        )
                        
                        LocalPushController.shared.sendLocalNotification(in: pushDuration + 3 * 24 * 60 * 60, title: "Survey Completion Still Pending", subtitle: "Thanks for participating. You can complete the exit survey at any time.", body: "It only takes about 3 minutes.", identifier: "survey-completion-notification-reminder")
                        
                        completion()
                    }
                }
                alert.addAction(proceedAction)
                UIViewController.topViewController()?.present(alert, animated: true)
            } else {
                completion()
            }
        }
    }
    
    public func manuallyGiveUserConsent(
        timeStamp: Date = Date(),
        userId: String?,
        completion: @escaping () -> Void
    ) {
        self.saveUserConsentHasBeenGiven(consentTimestamp: timeStamp, completion: completion)
        if let userId {
            self.userIdentifier = userId
        }
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
    
    /// Resets the UUID of the study 
    open func reset() {
        let newLocalUserIdentifier = "\(studyIdentifier)-\(UUID().uuidString)"
        self.userIdentifier = newLocalUserIdentifier
    }
    
    // MARK: - Improved File Handling -
    
    public func studyContainer() -> URL {
        
        let fileManager = FileManager.default
        let documentDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let studyDirectoryURL = documentDirectoryURL
            .appendingPathComponent("OpenResearchKit/Studies", isDirectory: true)
            .appendingPathComponent(studyIdentifier, isDirectory: true)
        
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
    
}

// MARK: - Accessors -

extension Study {
    
    /// Indicates whether the study is currently active and eligible for data collection.
    ///
    /// For data donation studies (which have no fixed duration), the study is considered active
    /// if the user has given consent and has not explicitly terminated participation.
    ///
    /// For regular studies, the study is active if the configured end date lies in the future.
    public var isActivelyRunning: Bool {
        
        if isDataDonationStudy {
            if hasUserGivenConsent && self.terminatedByUserDate == nil {
                return true
            }
            return false
        }
        
        if let studyEndDate = studyEndDate {
            if studyEndDate.isInFuture {
                return true
            }
        }
        
        return false
    }
    
    public var isDismissedByUser: Bool {
        get {
            studyUserDefaults["isDismissedByUser"] as? Bool ?? false
        }
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["isDismissedByUser"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    public var userConsentDate: Date? {
        return studyUserDefaults["userConsentDate"] as? Date
    }
    
    public var hasUserGivenConsent: Bool {
        return userConsentDate != nil
    }
    
    public var hasCompletedTerminationSurvey: Bool {
        get {
            return studyUserDefaults["hasCompletedTerminationSurvey"] as? Bool ?? false
        }
        
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["hasCompletedTerminationSurvey"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
                if newValue {
                    LocalPushController.clearNotifications(with: "survey-completion-notification")
                    LocalPushController.clearNotifications(with: "survey-completion-notification-reminder")
                }
            }
        }
    }
    
    public var hasCompletedMidSurvey: Bool {
        get {
            return studyUserDefaults["hasCompletedMidSurvey"] as? Bool ?? false
        }
        
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["hasCompletedMidSurvey"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
                if newValue {
                    LocalPushController.clearNotifications(with: "mid-study-survey-notification")
                    LocalPushController.clearNotifications(with: "mid-study-survey-notification-reminder")
                }
            }
        }
    }
    
    public var shouldDisplayMidSurvey: Bool {
        
        if let midStudySurvey, let userConsentDate {
            let showAfterDate = userConsentDate.addingTimeInterval(midStudySurvey.showAfter)
            if !showAfterDate.isInFuture && !hasCompletedMidSurvey {
                return true
            }
        }
        
        
        return false
    }
    
    public var shouldDisplayTerminationSurvey: Bool {
        if let studyEndDate = self.studyEndDate {
            return !studyEndDate.isInFuture && !hasCompletedTerminationSurvey && !isDismissedByUser
        }
        
        return false
    }
    
    public var assignedGroup: String? {
        get {
            if self.isActivelyRunning {
                return studyUserDefaults["assignedGroup"] as? String
            }
            return nil
        }
        
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["assignedGroup"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    public var studyEndDate: Date? {
        if let terminatedByUserDate = self.terminatedByUserDate {
            return terminatedByUserDate
        }
        
        return userConsentDate?.addingTimeInterval(studyInformation.duration ?? 0)
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
    
    private var terminatedByUserDate: Date? {
        get {
            studyUserDefaults["terminatedByUserDate"] as? Date
        }
        
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["terminatedByUserDate"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
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
    
    internal var JSONFile: [ [String: Any] ] {
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
        return studyUserDefaults["lastSuccessfulUploadDate"] as? Date
    }
    
    public func updateUploadDate(newDate: Date = Date()) {
        var studyUserDefaults = self.studyUserDefaults
        studyUserDefaults["lastSuccessfulUploadDate"] = newDate
        self.save(studyUserDefaults: studyUserDefaults)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public func uploadIfNecessary() {
        
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
    
    public func uploadJSONImmediately() {
        self.uploadJSON()
    }
    
    private func uploadJSON() {
        
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

struct OpenResearchKit {
    
    static func researchKitDefaults(appGroup: String?) -> [String: [String: Any]] {
        if let appGroup {
            return UserDefaults(suiteName: appGroup)!.dictionary(forKey: "open_research_kit") as? [String: [String: Any]] ?? [:]
        }
        return UserDefaults.standard.dictionary(forKey: "open_research_kit") as? [String: [String: Any]] ?? [:]
    }
    
    static func saveStudyDefaults(defaults: [String: Any], appGroup: String?, studyIdentifier: String) {
        var currentDefaults = researchKitDefaults(appGroup: appGroup)
        currentDefaults[studyIdentifier] = defaults
        if let appGroup {
            UserDefaults(suiteName: appGroup)!.set(currentDefaults, forKey: "open_research_kit")
        } else {
            UserDefaults.standard.set(currentDefaults, forKey: "open_research_kit")
        }
    }
    
}

extension Date {
    var isInFuture: Bool {
        return self.timeIntervalSinceNow > 0
    }
}


