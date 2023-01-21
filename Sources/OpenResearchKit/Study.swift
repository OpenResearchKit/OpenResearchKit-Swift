//
//  File.swift
//
//
//  Created by Frederik Riedel on 18.11.22.
//

import Foundation
import SwiftUI
#if !os(watchOS)
import UIKit
import WebKit
#endif
import os

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "OpenResearchKit"
)

public class Study: ObservableObject {
    
    public init(title: String,
                subtitle: String,
                duration: TimeInterval,
                studyIdentifier: String,
                universityLogo: UIImage,
                contactEmail: String,
                introductorySurveyURL: URL,
                concludingSurveyURL: URL,
                fileSubmissionServer: URL,
                apiKey: String,
                uploadFrequency: TimeInterval = 60 * 60 * 24,
                installDate: Date? = nil,
                defaults: UserDefaults = .standard) {
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
        self.studyIdentifier = studyIdentifier
        self.universityLogo = universityLogo
        self.contactEmail = contactEmail
        self.introductorySurveyURL = introductorySurveyURL
        self.concludingSurveyURL = concludingSurveyURL
        self.fileSubmissionServer = fileSubmissionServer
        self.apiKey = apiKey
        self.uploadFrequency = uploadFrequency
        self.installDate = installDate
        self.defaults = defaults
        
#if DEBUG && !os(watchOS)
        LocalPushController.shared.sendLocalNotification(in: 10, title: "Concluding our Study", subtitle: "Please fill out the post-study-survey", body: "It’s just 3 minutes to complete the survey.", identifier: "survey-completion-notification")
#endif
    }
    
    public let title: String
    public let subtitle: String
    public let duration: TimeInterval
    public let studyIdentifier: String
    public let universityLogo: UIImage
    public let contactEmail: String
    public let introductorySurveyURL: URL
    public let concludingSurveyURL: URL
    public let fileSubmissionServer: URL
    public let apiKey: String
    public let uploadFrequency: TimeInterval
    public var installDate: Date?
    public let defaults: UserDefaults
    
    @Published public var dataURL: String?
    
    public static var example: Study {
        Study(title: "Example Project",
              subtitle: "Participate in a study together with the Example Institute to help us understand how different personalities use Example.",
              duration: 60 * 60 * 24 * 7 * 6, // 6 weeks
              studyIdentifier: "example-study",
              universityLogo: UIImage(),
              contactEmail: "contact@example.com",
              introductorySurveyURL: URL(string: "http://example.com/intro")!,
              concludingSurveyURL: URL(string: "http://example.com/outro")!,
              fileSubmissionServer: URL(string: "https://example.com/files")!,
              apiKey: "example-key",
              installDate: Date().addingTimeInterval(-3600),
              defaults: .standard)
    }
    
    private var JSONFile: [ [String: Any] ] {
        if let jsonData = try? Data(contentsOf: jsonDataFilePath),
           let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let json = decoded as? [ [String: Any] ] {
            return json
        }
        
        return []
    }
    
    public var lastSuccessfulUploadDate: Date? {
        get {
            return defaults.value(forKey: "openresearchkit.last_upload." + self.studyIdentifier) as? Date
        }
        set {
            defaults.set(newValue, forKey: "openresearchkit.last_upload." + self.studyIdentifier)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    public func updateUploadDate(newDate: Date = Date()) {
        self.lastSuccessfulUploadDate = newDate
    }
    
    public func appendNewJSONObjects(newObjects: [ [String: JSONConvertible] ]) {
        var existingFile = self.JSONFile
        existingFile.append(contentsOf: newObjects)
        self.saveAndUploadIfNeccessary(jsonFile: existingFile)
        logger.info("Append new json: \(newObjects)")
    }
    
    private func saveAndUploadIfNeccessary(jsonFile: [ [String: Any] ]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonFile, options: .prettyPrinted) {
            try? jsonData.write(to: jsonDataFilePath)
            self.uploadIfNecessary()
        }
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
    
    /// A user is eligible if their device is set to English, and they installed the app less then 7 days ago.
    public var isUserEligible: Bool {
        guard Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? false else {
            return false
        }
        if let installDate = self.installDate {
            return installDate.addingTimeInterval(60 * 60 * 24 * 2).isInFuture
        }
        return false
    }
    
    
    #if !os(watchOS)
    public var visibleSurveyType: SurveyType? {
        if self.shouldDisplayTerminationSurvey {
            return .completion
        } else if !self.isDismissedByUser && self.userConsentDate == nil && self.isUserEligible {
            return .introductory
        }
        return nil
    }
    #endif
    
    private var isCurrentlyUploading = false
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
        
        
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadFrequency {
            self.uploadJSON()
        }
    }
    
    public func uploadJSON() {
        
        if isCurrentlyUploading {
            return
        }
        
        isCurrentlyUploading = true
        
        if let data = try? Data(contentsOf: jsonDataFilePath) {
            
            let uploadSession = MultipartFormDataRequest(url: self.fileSubmissionServer)
            uploadSession.addTextField(named: "api_key", value: self.apiKey)
            uploadSession.addTextField(named: "user_key", value: self.userIdentifier)
            uploadSession.addDataField(named: "file", filename: self.fileName, data: data, mimeType: "application/octet-stream")
            
            
            let task = URLSession.shared.dataTask(with: uploadSession) { data, response, error in
                self.isCurrentlyUploading = false
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let result = json["result"] as? [String: Any], let hadSuccess = result["success"] as? String {
                        if let path = result["path"] as? String {
                            self.dataURL = path
                        }
                        logger.info("Uploaded JSON (success=\(hadSuccess)) with response: \(json)")
                        if hadSuccess == "true" {
                            DispatchQueue.main.async {
                                self.updateUploadDate()
                            }
                        }
                    }
                }
            }
            task.resume()
            
        } else {
            self.isCurrentlyUploading = false
        }
        
    }
    
    private var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    private var fileName: String {
        "study-\(studyIdentifier)-\(userIdentifier).json"
    }
    
    private var jsonDataFilePath: URL {
        let readPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
        print(readPath.absoluteString)
        return readPath
    }
    
#if !os(watchOS)
    public var invitationBannerView: some View {
        StudyBannerInvitation(study: self, surveyType: .introductory)
    }
    
    public var terminationBannerView: some View {
        StudyBannerInvitation(study: self, surveyType: .completion)
    }
    public var detailInfosView: some View {
        StudyActiveDetailInfos()
            .environmentObject(self)
    }
#endif
    
    public var hasUserGivenConsent: Bool {
        return userConsentDate != nil
    }
    
    public var userConsentDate: Date? {
        return studyUserDefaults["userConsentDate"] as? Date
    }
    
    public func saveUserConsentHasBeenGiven(consentTimestamp: Date) {
        var studyUserDefaults = self.studyUserDefaults
        studyUserDefaults["userConsentDate"] = consentTimestamp
        self.save(studyUserDefaults: studyUserDefaults)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public var isActivelyRunning: Bool {
        if let studyEndDate = studyEndDate {
            if studyEndDate.isInFuture {
                return true
            }
        }
        
        return false
    }

     public var isFinished: Bool {
        !(studyEndDate?.isInFuture ?? true)
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
    
    var terminatedByUserDate: Date? {
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
    
    public var studyEndDate: Date? {
        if let terminatedByUserDate = self.terminatedByUserDate {
            return terminatedByUserDate
        }
        
        return userConsentDate?.addingTimeInterval(duration)
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
            }
        }
    }
    
    public var shouldDisplayIntroductorySurvey: Bool {
        !hasUserGivenConsent && !isDismissedByUser
    }
    
    public var shouldDisplayTerminationSurvey: Bool {
        if let studyEndDate = self.studyEndDate {
            return !studyEndDate.isInFuture && !hasCompletedTerminationSurvey && self.terminatedByUserDate == nil && !isDismissedByUser
        }
        
        return false
    }
    
    public var userIdentifier: String {
        var studyUserDefaults = self.studyUserDefaults
        
        if let localUserIdentifier = studyUserDefaults["localUserIdentifier"] as? String {
            return localUserIdentifier
        }
        
        let newLocalUserIdentifier = "\(studyIdentifier)-\(UUID().uuidString)"
        studyUserDefaults["localUserIdentifier"] = newLocalUserIdentifier
        self.save(studyUserDefaults: studyUserDefaults)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        return newLocalUserIdentifier
    }
    
    public var shouldDisplayWeeklyCheckIn: Bool {
        guard self.isActivelyRunning, let consentDate = self.userConsentDate else {
            return false
        }
        return consentDate.addingTimeInterval(Double(self.lastCheckInWeek + 1) * 60 * 60 * 24 * 7) < Date()
    }
    
    public func displayedWeeklyCheckIn(at date: Date = .init()) {
        guard let consentDate = self.userConsentDate else {
            return
        }
        self.lastCheckInWeek = Int(-consentDate.timeIntervalSinceNow / 60 / 60 / 24 / 7)
        
    }

    public var lastCheckInWeek: Int {
        get {
            self.studyUserDefaults["lastCheckInWeek"] as? Int ?? 0
        }
        set {
            self.studyUserDefaults["lastCheckInWeek"] = newValue
        }
    }
    
    public var additionalDefaults: [String: Any] {
        get {
            self.studyUserDefaults["additionalDefaults"] as? [String: Any] ?? [:]
        }
        set {
            var defaults = self.studyUserDefaults
            defaults["additionalDefaults"] = newValue
            self.save(studyUserDefaults: defaults)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
  
    
    
    
    var studyUserDefaults: [String: Any] {
        get {
            self.researchKitDefaults[self.studyIdentifier] ?? [:]
        }
        set {
            self.save(studyUserDefaults: newValue)
        }
    }
    
    func save(studyUserDefaults: [String: Any]) {
        self.saveStudyDefaults(defaults: studyUserDefaults, studyIdentifier: self.studyIdentifier)
    }
    
#if !os(watchOS)
    public func showCompletionSurvey() {
        let surveyView = SurveyWebView(study: self, surveyType: .completion)
        let hostingCOntroller = UIHostingController(rootView: surveyView)
        hostingCOntroller.modalPresentationStyle = .fullScreen
        UIViewController.topViewController()?.present(hostingCOntroller, animated: true)
    }
    
    public func surveyUrl(for surveyType: SurveyType) -> URL {
        switch surveyType {
        case .introductory:
            return self.introductorySurveyURL.appendingQueryItem(name: "uuid", value: self.userIdentifier)
        case .completion:
            return self.concludingSurveyURL.appendingQueryItem(name: "uuid", value: self.userIdentifier)
        }
    }
#endif
    
    
    var researchKitDefaults: [String: [String: Any]] {
        get {
            defaults.dictionary(forKey: Self.defaultsKey) as? [String: [String: Any]] ?? [:]
        }
    }
    
    func saveStudyDefaults(defaults: [String: Any], studyIdentifier: String) {
        var currentDefaults = researchKitDefaults
        currentDefaults[studyIdentifier] = defaults
        self.defaults.set(currentDefaults, forKey: Self.defaultsKey)
    }
    
    public static var defaultsKey: String = "open_research_kit"
    
    public static var universityLogo: UIImage? {
        UIImage(named: "university_header", in: .module, with: .none)
    }
}


