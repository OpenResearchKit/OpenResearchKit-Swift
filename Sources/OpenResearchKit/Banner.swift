//
//  File.swift
//  
//
//  Created by Leo Mehlig on 14.12.22.
//

#if !os(watchOS)
import Foundation
import SwiftUI


public enum SurveyType {
    case introductory, completion
}

public struct StudyBannerInvitation: View {
    
    @ObservedObject var study: Study
    let surveyType: SurveyType
    @State private var showSurvey: Bool = false
    
    public init(study: Study, surveyType: SurveyType) {
        self.study = study
        self.surveyType = surveyType
    }
    
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
            SurveyWebView(study: study, surveyType: surveyType)
        }
    }
}

#endif
