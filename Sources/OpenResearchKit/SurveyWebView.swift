//
//  SwiftUIView.swift
//  
//
//  Created by Frederik Riedel on 16.01.23.
//

import SwiftUI
import WebKit

enum SurveyType {
    case introductory, mid, completion
}

import UIKit
// this is a web view on purpose so that users cant share the URL
struct SurveyWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var study: Study
    
    
    let surveyType: SurveyType
    
    var body: some View {
        NavigationView {
            if let surveyUrl = study.surveyUrl(for: surveyType) {
                ResearchWebView(url: surveyUrl, completion: { (success, parameters) in
                    if surveyType == .introductory {
                        if success {
                            // schedule push notification for study completed date -> in 6 weeks
                            // automatically opens completion survey
                           
                            if let group = parameters["assignedGroup"] {
                                study.assignedGroup = group
                            }
                            
                            study.saveUserConsentHasBeenGiven(consentTimestamp: Date()) {
                                presentationMode.wrappedValue.dismiss()
                                
                                study.introSurveyComletionHandler?(
                                    parameters
                                )
                            }
                            
                        } else {
                            study.isDismissedByUser = true
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else if surveyType == .completion {
                        presentationMode.wrappedValue.dismiss()
                        study.hasCompletedTerminationSurvey = true
                    } else if surveyType == .mid {
                        presentationMode.wrappedValue.dismiss()
                        study.hasCompletedMidSurvey = true
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
}


import SwiftUI
import WebKit

public struct ResearchWebView: UIViewRepresentable {
    
    public let url: URL
    public let completion: (Bool, [String: String]) -> ()
    
    public init(url: URL, completion: @escaping (Bool, [String: String]) -> ()) {
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
