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
    
    public init(title: String, subtitle: String, duration: TimeInterval, identifier: String, universityLogo: UIImage, contactEmail: String, introductorySurveyURL: URL, concludingSurveyURL: URL, fileSubmissionServer: URL, apiKey: String, uploadFrequency: TimeInterval) {
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
        self.identifier = identifier
        self.universityLogo = universityLogo
        self.contactEmail = contactEmail
        self.introductorySurveyURL = introductorySurveyURL
        self.concludingSurveyURL = concludingSurveyURL
        self.fileSubmissionServer = fileSubmissionServer
        self.apiKey = apiKey
        self.uploadFrequency = uploadFrequency
    }
    
    let title: String
    let subtitle: String
    let duration: TimeInterval
    let identifier: String
    let universityLogo: UIImage
    let contactEmail: String
    let introductorySurveyURL: URL
    let concludingSurveyURL: URL
    let fileSubmissionServer: URL
    let apiKey: String
    let uploadFrequency: TimeInterval
    
    private var JSONFile: [ [String: JSONConvertible] ] {
        if let dict = NSArray(contentsOf: jsonDataFilePath) as?  [ [ String: JSONConvertible ] ] {
            return dict
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
        var existingFile = self.JSONFile
        existingFile.append(contentsOf: newObjects)
        self.saveAndUploadIfNeccessary(jsonFile: existingFile)
    }
    
    private func saveAndUploadIfNeccessary(jsonFile: [ [String: JSONConvertible] ]) {
        let array = NSArray(array: jsonFile)
        array.write(toFile: jsonDataFilePath.path, atomically: true)
        self.uploadIfNecessary()
    }
    
    private var isCurrentlyUploading = false
    public func uploadIfNecessary() {
        
        if isCurrentlyUploading {
            return
        }
        
        guard let lastSuccessfulUploadDate = self.lastSuccessfulUploadDate else {
            self.uploadJSON()
            return
        }
        
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadFrequency {
            self.uploadJSON()
        }
    }
    
    private func uploadJSON() {
        
        isCurrentlyUploading = true
        
        if let data = try? Data(contentsOf: jsonDataFilePath) {
            
            let uploadSession = MultipartFormDataRequest(url: URL(string: "https://mknztlfet6msiped4d5iuixssy0iekda.lambda-url.eu-central-1.on.aws")!)
            uploadSession.addTextField(named: "api_key", value: self.apiKey)
            uploadSession.addTextField(named: "user_key", value: self.identifier)
            uploadSession.addDataField(named: "file", filename: self.fileName, data: data, mimeType: "application/octet-stream")


            let task = URLSession.shared.dataTask(with: uploadSession) { data, response, error in
                print(error)
                print(response)
                if let data = data {
                    self.isCurrentlyUploading = false
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
            

//            AF.upload(multipartFormData: { multiPart in
//                multiPart.append(self.apiKey.data(using: .utf8)!, withName: "api_key")
//                multiPart.append(self.identifier.data(using: .utf8)!, withName: "user_key")
//                multiPart.append(data, withName: "file", fileName: self.fileName, mimeType: "application/octet-stream")
//            }, to: "https://mknztlfet6msiped4d5iuixssy0iekda.lambda-url.eu-central-1.on.aws")
//            .uploadProgress(queue: .main) { progress in
//                print("Upload Progress: \(progress.fractionCompleted)")
//            }
//            .responseJSON { response in
//                switch response.result {
//                case .success(let result):
//                    self.isCurrentlyUploading = false
//                    if let json = result as? [String: Any], let result = json["result"] as? [String: Any], let hadSuccess = result["success"] as? String {
//                        print(hadSuccess)
//                        print(json)
//                        if hadSuccess == "true" {
//                            self.updateUploadDate()
//                        }
//                    }
//                case .failure(let error):
//                    self.isCurrentlyUploading = false
//                    print(error)
//                }
//            }
//
//            AF.upload(multipartFormData: { multiPart in
//                multiPart.append(self.apiKey.data(using: .utf8)!, withName: "api_key")
//                multiPart.append(data, withName: "file", fileName: self.fileName, mimeType: "application/octet-stream")
//            }, with: URLRequest(url: URL(string: "https://mknztlfet6msiped4d5iuixssy0iekda.lambda-url.eu-central-1.on.aws")!))
//            .uploadProgress(queue: .main) { progress in
//                print("Upload Progress: \(progress.fractionCompleted)")
//            }
//            .responseJSON { response in
//                print("done: \(response)")
//            }
        } else {
            self.isCurrentlyUploading = false
        }

    }
    
    private var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    private var fileName: String {
        "study-\(identifier)-\(localUserIdentifier).plist"
    }
    
    private var jsonDataFilePath: URL {
        let readPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
        return readPath
    }
    
    public var invitationBannerView: StudyBannerInvitation {
        StudyBannerInvitation(study: self)
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
        if let userConsentDate = userConsentDate {
            if userConsentDate.addingTimeInterval(duration).isInFuture {
                return true
            }
        }
        
        return false
    }
    
    public var localUserIdentifier: String {
        var studyUserDefaults = self.studyUserDefaults
        
        if let localUserIdentifier = studyUserDefaults["localUserIdentifier"] as? String {
            return localUserIdentifier
        }
        
        let newLocalUserIdentifier = "\(identifier)-\(UUID().uuidString)"
        studyUserDefaults["localUserIdentifier"] = newLocalUserIdentifier
        self.save(studyUserDefaults: studyUserDefaults)
        objectWillChange.send()
        return newLocalUserIdentifier
    }
    
    
    
    
    var studyUserDefaults: [String: Any] {
        OpenResearchKit.researchKitDefaults[self.identifier] ?? [:]
    }
    
    func save(studyUserDefaults: [String: Any]) {
        OpenResearchKit.saveStudyDefaults(defaults: studyUserDefaults, studyIdentifier: self.identifier)
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
    
    @State var showSurveyView: Bool = false
    @State var showStudyIntroductoryView: Bool = false
    
    internal init(study: Study) {
        self.study = study
    }
    
    
    let study: Study
    
    public var body: some View {
        Button {
            //            self.showSurveyView = true
            self.showStudyIntroductoryView = true
        } label: {
            HStack {
                
                VStack(alignment: .leading, spacing: 2) {
                    Image(uiImage: study.universityLogo)
                        .resizable()
                        .scaledToFit()
                        .mask(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    Text(study.title)
                        .foregroundColor(.primary)
                        .font(.headline)
                        .bold()
                    Text(study.subtitle)
                        .foregroundColor(.secondary)
                    Button {
                        
                    } label: {
                        Text("Dismiss")
                            .bold()
                    }
                    .padding(.top)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .fullScreenCover(isPresented: $showSurveyView) {
            SurveyWebView(url: self.study.introductorySurveyURL)
        }
        .sheet(isPresented: $showStudyIntroductoryView) {
            StudyIntroductionView(study: study)
        }
    }
}


struct StudyIntroductionView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var showIntroSurvey = false
    
    let study: Study
    
    var body: some View {
        ScrollView {
            Image(uiImage: study.universityLogo)
                .resizable()
                .scaledToFit()
            VStack(alignment: .leading, spacing: 4) {
                Text(study.title)
                    .font(.title)
                    .bold()
                Text("""
    Thank you for your interest in the study that we aim to conduct together with the Max Planck Institute for Human Development and the Univeristy of Heidelberg.
    
    Our goal is to examine the effects of “one sec” and ultimately improve the experience even more.
    
    Dont worry, if you chose to participate all data is shared anonymously and cannot be linked to you (in fact, one sec doesn’t even know who you are, there is no login or personal information input in this app).
    
    Thanks a lot for your help!
    """)
                .multilineTextAlignment(.leading)
            }
            .padding()
        }
        VStack(spacing: 12) {
            Button {
                self.showIntroSurvey = true
            } label: {
                Text("Continue to Study")
            }
            .buttonStyle(BigButtonStyle(backgroundColor: .blue, textColor: .black))
            .fullScreenCover(isPresented: $showIntroSurvey) {
                SurveyWebView(url: study.introductorySurveyURL)
            }
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Maybe later")
            }
            .padding(12)
        }
        .padding()
    }
}




// this is a web view on purpose so that users cant share the URL
struct SurveyWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    let url: URL
    var body: some View {
        NavigationView {
            WebView(url: url)
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
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
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
extension Date: JSONConvertible {}
extension Int: JSONConvertible {}
extension Double: JSONConvertible {}
extension Data: JSONConvertible {}
extension Bool: JSONConvertible {}
extension Array<JSONConvertible>: JSONConvertible {}
extension Dictionary<String, JSONConvertible>: JSONConvertible {}

extension Date {
    var isInFuture: Bool {
        return self.timeIntervalSinceNow > 0
    }
}
