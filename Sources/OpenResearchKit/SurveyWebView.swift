//
//  SwiftUIView.swift
//  
//
//  Created by Frederik Riedel on 16.01.23.
//

import SwiftUI
import WebKit

enum SurveyType {
    case introductory, completion
}

import UIKit
// this is a web view on purpose so that users cant share the URL
struct SurveyWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var study: Study
    
    
    let surveyType: SurveyType
    
    var body: some View {
        NavigationView {
            ResearchWebView(url: study.surveyUrl(for: surveyType), completion: { (success, parameters) in
                if surveyType == .introductory {
                    if success {
                        // schedule push notification for study completed date -> in 6 weeks
                        // automatically opens completion survey
                        study.saveUserConsentHasBeenGiven(consentTimestamp: Date())
                       
                        if let group = parameters["assignedGroup"] {
                            study.assignedGroup = group
                        }
                        
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
                        
                        UIViewController.topViewController()?.dismiss(animated: false, completion: {
                            study.introSurveyComletionHandler?(
                                parameters
                            )
                            
                            UIViewController.topViewController()?.present(alert, animated: true)
                        })
                        
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

public struct ResearchWebView: UIViewRepresentable {
    
    public let url: URL
    public let completion: (Bool, [String: String]) -> ()
    
    public init(url: URL, completion: (Bool, [String: String]) -> ()) {
        self.url = url
        self.completion = completion
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        DispatchQueue.main.async {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completion)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        internal init(completion: @escaping (Bool, [String: String]) -> ()) {
            self.completion = completion
        }
        
        let completion: (Bool, [String: String]) -> ()
        
        public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            if let url = webView.url {
                let urlString = url.absoluteString
                if urlString.contains("survey-callback/success") {
                    self.completion(true, url.queryParameters ?? [:])
                } else if urlString.contains("survey-callback/failed") {
                    self.completion(false, url.queryParameters ?? [:])
                }
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
        }
    }
}


extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
