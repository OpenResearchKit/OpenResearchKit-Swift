//
//  File.swift
//  
//
//  Created by Frederik Riedel on 18.11.22.
//

import Foundation
import UIKit
import FredKit
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
    
    
    public var invitationBannerView: StudyBannerInvitation {
        StudyBannerInvitation(study: self)
    }
    
    public var hasUserGivenConsent: Bool {
        return userConsentDate != nil
    }
    
    public var userConsentDate: Date? {
        return studyUserDefaults?["userConsentDate"] as? Date
    }
    
    public func saveUserConsentHasBeenGiven(consentTimestamp: Date) {
        var studyUserDefaults = self.studyUserDefaults ?? [:]
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
        var studyUserDefaults = self.studyUserDefaults ?? [:]
        
        if let localUserIdentifier = studyUserDefaults["localUserIdentifier"] as? String {
            return localUserIdentifier
        }
        
        let newLocalUserIdentifier = "\(identifier)-\(UUID().uuidString)"
        studyUserDefaults["localUserIdentifier"] = newLocalUserIdentifier
        self.save(studyUserDefaults: studyUserDefaults)
        objectWillChange.send()
        return newLocalUserIdentifier
    }
    
   
    
    
    var studyUserDefaults: [String: Any]? {
        UserDefaults.standard.dictionary(forKey: "open_research_kit")
    }
    
    func save(studyUserDefaults: [String: Any]) {
        UserDefaults.standard.setValue(studyUserDefaults, forKey: "open_research_kit")
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
