//
//  SurveyWebView.swift
//
//
//  Created by Frederik Riedel on 16.01.23.
//

import SwiftUI
import WebKit
import SwiftUI
import WebKit
import UIKit

/// A SwiftUI wrapper around a `WKWebView` that loads survey URLs in an isolated, non-shareable context.
///
/// This view prevents users from accessing or sharing custom or personalized survey URLs by rendering
/// them in a native WebView instead of Safari. It handles the display and dismissal of introductory,
/// mid, and completion surveys, and processes metadata returned via URL parameters to persist study state.
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
                            } else if let group = parameters["groupid"] {
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
