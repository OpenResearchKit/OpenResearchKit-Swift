//
//  File.swift
//  
//
//  Created by Frederik Riedel on 18.11.22.
//

import Foundation
import UIKit
import SwiftUI

public class Study: ObservableObject {
    
    public init(title: String, subtitle: String, duration: TimeInterval, studyIdentifier: String, universityLogo: UIImage, contactEmail: String, introductorySurveyURL: URL, concludingSurveyURL: URL, fileSubmissionServer: URL, apiKey: String, uploadFrequency: TimeInterval) {
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
        
        #if DEBUG
        LocalPushController.shared.sendLocalNotification(in: 10, title: "Concluding our Study", subtitle: "Please fill out the post-study-survey", body: "It’s just 3 minutes to complete the survey.", identifier: "survey-completion-notification")
        #endif
    }
    
    let title: String
    let subtitle: String
    let duration: TimeInterval
    let studyIdentifier: String
    let universityLogo: UIImage
    let contactEmail: String
    let introductorySurveyURL: URL
    let concludingSurveyURL: URL
    let fileSubmissionServer: URL
    let apiKey: String
    let uploadFrequency: TimeInterval
    
    private var JSONFile: [ [String: Any] ] {
        if let jsonData = try? Data(contentsOf: jsonDataFilePath),
           let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let json = decoded as? [ [String: Any] ] {
            return json
        }

        return []
    }
    
    public var lastSuccessfulUploadDate: Date? {
        return studyUserDefaults["lastSuccessfulUploadDate"] as? Date
    }
    
    public func updateUploadDate(newDate: Date = Date()) {
        var studyUserDefaults = self.studyUserDefaults
        studyUserDefaults["lastSuccessfulUploadDate"] = newDate
        self.save(studyUserDefaults: studyUserDefaults)
        objectWillChange.send()
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
    
    public var isDismissedByUser: Bool {
        get {
            studyUserDefaults["isDismissedByUser"] as? Bool ?? false
        }
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["isDismissedByUser"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            objectWillChange.send()
        }
    }
    
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
    
    private func uploadJSON() {
        
        if isCurrentlyUploading {
            return
        }
        
        isCurrentlyUploading = true
        
        if let data = try? Data(contentsOf: jsonDataFilePath) {
            
            let uploadSession = MultipartFormDataRequest(url: URL(string: "https://mknztlfet6msiped4d5iuixssy0iekda.lambda-url.eu-central-1.on.aws")!)
            uploadSession.addTextField(named: "api_key", value: self.apiKey)
            uploadSession.addTextField(named: "user_key", value: self.userIdentifier)
            uploadSession.addDataField(named: "file", filename: self.fileName, data: data, mimeType: "application/octet-stream")


            let task = URLSession.shared.dataTask(with: uploadSession) { data, response, error in
                self.isCurrentlyUploading = false
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let result = json["result"] as? [String: Any], let hadSuccess = result["success"] as? String {
                        print(hadSuccess)
                        print(json)
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
    
    public var invitationBannerView: some View {
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(self)
    }
    
    public var terminationBannerView: some View {
        StudyBannerInvitation(surveyType: .completion)
            .environmentObject(self)
    }
    
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
        objectWillChange.send()
    }
    
    public var isActivelyRunning: Bool {
        if let studyEndDate = studyEndDate {
            if studyEndDate.isInFuture {
                return true
            }
        }
        
        return false
    }
    
    public var studyEndDate: Date? {
        userConsentDate?.addingTimeInterval(duration)
    }
    
    public var hasCompletedTerminationSurvey: Bool {
        get {
            return studyUserDefaults["hasCompletedTerminationSurvey"] as? Bool ?? false
        }
        
        set {
            var studyUserDefaults = self.studyUserDefaults
            studyUserDefaults["hasCompletedTerminationSurvey"] = newValue
            self.save(studyUserDefaults: studyUserDefaults)
            objectWillChange.send()
        }
    }
    
    public var shouldDisplayIntroductorySurvey: Bool {
        !hasUserGivenConsent && !isDismissedByUser
    }
    
    public var shouldDisplayTerminationSurvey: Bool {
        if let studyEndDate = self.studyEndDate {
            return studyEndDate.isInFuture && !hasCompletedTerminationSurvey
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
        objectWillChange.send()
        return newLocalUserIdentifier
    }
    
    
    
    
    var studyUserDefaults: [String: Any] {
        OpenResearchKit.researchKitDefaults[self.studyIdentifier] ?? [:]
    }
    
    func save(studyUserDefaults: [String: Any]) {
        OpenResearchKit.saveStudyDefaults(defaults: studyUserDefaults, studyIdentifier: self.studyIdentifier)
    }
    
    public func showCompletionSurvey() {
        let surveyView = SurveyWebView(surveyType: .completion).environmentObject(self)
        let hostingCOntroller = UIHostingController(rootView: surveyView)
        hostingCOntroller.modalPresentationStyle = .fullScreen
        UIViewController.topViewController()?.present(hostingCOntroller, animated: true)
    }
    
    func surveyUrl(for surveyType: SurveyType) -> URL {
        switch surveyType {
        case .introductory:
            return self.introductorySurveyURL.appendingQueryItem(name: "uuid", value: self.userIdentifier)
        case .completion:
            return self.concludingSurveyURL.appendingQueryItem(name: "uuid", value: self.userIdentifier)
        }
    }
}

struct OpenResearchKit {
    static var researchKitDefaults: [String: [String: Any]] {
        get {
            UserDefaults.standard.dictionary(forKey: "open_research_kit") as? [String: [String: Any]] ?? [:]
        }
    }
    
    static func saveStudyDefaults(defaults: [String: Any], studyIdentifier: String) {
        var currentDefaults = researchKitDefaults
        currentDefaults[studyIdentifier] = defaults
        UserDefaults.standard.set(currentDefaults, forKey: "open_research_kit")
    }
}

import SafariServices
public struct StudyBannerInvitation: View {
    
    let surveyType: SurveyType
    
    @State var showSurvey: Bool = false
    
    @EnvironmentObject var study: Study
    
    public var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            Image(uiImage: study.universityLogo)
                .resizable()
                .scaledToFit()
                .mask(RoundedRectangle(cornerRadius: 12))
                .padding(.vertical)
            if surveyType == .introductory {
                Text(study.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                Text(study.subtitle)
                    .foregroundColor(.secondary)
            } else {
                Text("Concluding our Study")
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                Text("Thanks a lot for parcitipating! The study is now terminated, please fill out the (very short) concluding survey!")
                    .foregroundColor(.secondary)
            }
            
            
            HStack {
                Text("Dismiss")
                    .bold()
                    .padding(.horizontal)
                    .opacity(0.66)
                    .onTapGesture {
                        study.isDismissedByUser = true
                    }
                
                HStack {
                    Spacer()
                    Text(surveyType == .introductory ? "Learn More" : "Complete")
                        .bold()
                        .foregroundColor(Color.accentColor)
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).foregroundColor(Color.accentColor.opacity(0.22)))
                .onTapGesture {
                    showSurvey = true
                }
            }
            .padding(.vertical)
        }
        .fullScreenCover(isPresented: $showSurvey) {
            SurveyWebView(surveyType: surveyType)
                .environmentObject(study)
        }
    }
}

enum SurveyType {
    case introductory, completion
}

import UIKit
// this is a web view on purpose so that users cant share the URL
struct SurveyWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var study: Study
    
    @State var showPushExplanation: Bool = false
    
    let surveyType: SurveyType
    
    var body: some View {
        NavigationView {
            WebView(url: study.surveyUrl(for: surveyType), completion: { success in
                if surveyType == .introductory {
                    if success {
                        // schedule push notification for study completed date -> in 6 weeks
                        // automatically opens completion survey
                        study.saveUserConsentHasBeenGiven(consentTimestamp: Date())
                        presentationMode.wrappedValue.dismiss()
                        
                        let alert = UIAlertController(title: "Post-Study-Questionnaire", message: "We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.", preferredStyle: .alert)
                        let proceedAction = UIAlertAction(title: "Proceed", style: .default) { _ in
                            LocalPushController.shared.askUserForPushPermission { success in
                                var pushDuration = study.duration
                                #if DEBUG
                                pushDuration = 10
                                #endif
                                LocalPushController.shared.sendLocalNotification(in: pushDuration, title: "Concluding our Study", subtitle: "Please fill out the post-study-survey", body: "It’s just 3 minutes to complete the survey.", identifier: "survey-completion-notification")
                            }
                        }
                        alert.addAction(proceedAction)
                        UIViewController.topViewController()?.present(alert, animated: true)
                        
                        self.showPushExplanation = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else if surveyType == .completion {
                    presentationMode.wrappedValue.dismiss()
                    study.hasCompletedTerminationSurvey = true
                }
            })
                .navigationTitle("Survey")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}


import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    var url: URL
    var completion: (Bool) -> ()
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        internal init(completion: @escaping (Bool) -> ()) {
            self.completion = completion
        }
        
        var completion: (Bool) -> ()
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            if let url = webView.url {
                let urlString = url.absoluteString
                if urlString.contains("survey-callback/success") {
                    self.completion(true)
                } else if urlString.contains("survey-callback/failed") {
                    self.completion(false)
                }
            }
        }
    }
}


struct BigButtonStyle: ButtonStyle {
    
    let backgroundColor: Color
    let textColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        
        HStack {
            Spacer()
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundColor(textColor)
            Spacer()
        }
        .padding(16)
        .background(backgroundColor)
        .mask(RoundedRectangle(cornerRadius: 12))
        .opacity(configuration.isPressed ? 0.6 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    func addDataField(named name: String, filename: String, data: Data, mimeType: String) {
        httpBody.append(dataFormField(named: name, filename: filename, data: data, mimeType: mimeType))
    }

    private func dataFormField(named name: String, filename: String,
                               data: Data,
                               mimeType: String) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }
    
    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody.append("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}

extension NSMutableData {
  func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

extension URLSession {
    func dataTask(with request: MultipartFormDataRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
    -> URLSessionDataTask {
        return dataTask(with: request.asURLRequest(), completionHandler: completionHandler)
    }
}


public protocol JSONConvertible {}
extension String: JSONConvertible {}
extension Int: JSONConvertible {}
extension Double: JSONConvertible {}
extension NSNumber: JSONConvertible {}
extension NSString: JSONConvertible {}
extension Bool: JSONConvertible {}
extension Array<JSONConvertible>: JSONConvertible {}
extension Dictionary<String, JSONConvertible>: JSONConvertible {}

extension Date {
    var isInFuture: Bool {
        return self.timeIntervalSinceNow > 0
    }
}

extension URL {

    func appendingQueryItem(name: String, value: String?) -> URL {

        var urlComponents = URLComponents(string: absoluteString)!

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

        // Create query item
        let queryItem = URLQueryItem(name: name, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        return urlComponents.url!
    }
}
