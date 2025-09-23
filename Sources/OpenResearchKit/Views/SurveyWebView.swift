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
public struct SurveyWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var study: Study
    
    let surveyType: SurveyType
    
    public init(surveyType: SurveyType) {
        self.surveyType = surveyType
    }
    
    public var body: some View {
        NavigationView {
            if let surveyUrl = study.surveyUrl(for: surveyType) {
                ResearchWebView(
                    url: surveyUrl,
                    completion: { (success, parameters) in
                        
                        if surveyType == .introductory {
                            
                            study.completeIntroductionSurvey()
                            
                            study.handleIntroductionSurveyResults(
                                consented: success,
                                parameters: parameters,
                                dismissView: {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            )
                            
                        } else if surveyType == .completion {
                            
                            presentationMode.wrappedValue.dismiss()
                            
                            if let study = study as? (any HasTerminationSurvey) {
                                study.hasCompletedTerminationSurvey = true
                            }
                            
                            study.isCompleted = true
                            
                        } else if surveyType == .mid {
                            
                            presentationMode.wrappedValue.dismiss()
                            
                            if let study = study as? (any HasMidSurvey) {
                                study.hasCompletedMidSurvey = true
                            }
                            
                        }
                    }
                )
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
