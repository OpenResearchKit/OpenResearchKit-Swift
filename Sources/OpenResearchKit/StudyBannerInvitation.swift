//
//  File.swift
//  
//
//  Created by Frederik Riedel on 13.01.23.
//

import SafariServices
import SwiftUI

public struct StudyBannerInvitation: View {
    
    let surveyType: SurveyType
    
    @State var showSurvey: Bool = false
    
    @EnvironmentObject var study: Study
    
    public var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
                    .opacity(0.75)
                    .onTapGesture {
                        study.isDismissedByUser = true
                    }
            }
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
                Text(study.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                Text("Thanks a lot for participating in the study, the 6 weeks of participation are now completed. Please fill out one last 3 minute survey!")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                Text(surveyType == .introductory ? "Learn more" : "Complete")
                    .bold()
                    .foregroundColor(Color.accentColor)
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).foregroundColor(Color.accentColor.opacity(0.22)))
            .onTapGesture {
                showSurvey = true
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
                                LocalPushController.shared.sendLocalNotification(in: pushDuration, title: "Concluding the study", subtitle: "Thanks for participating. Please fill out one last survey.", body: "It only takes 3 minutes to complete this survey.", identifier: "survey-completion-notification")
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
    
    let url: URL
    let completion: (Bool) -> ()
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        DispatchQueue.main.async {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        
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
