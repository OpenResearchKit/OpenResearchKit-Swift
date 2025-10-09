//
//  StudyBannerInvitation.swift
//
//
//  Created by Frederik Riedel on 13.01.23.
//

import SafariServices
import SwiftUI
import UIKit

public struct StudyBannerInvitation: View {
    
    let surveyType: SurveyType
    
    @EnvironmentObject var study: Study
    
    public var body: some View {
        
        DefaultStudyView(
            studyMetadata: study.studyInformation,
            studyDuration: studyDuration,
            surveyType: surveyType,
            dismissStudy: {
                study.isDismissedByUser = true
            },
            primaryAction: {
                let surveyView = UIHostingController(
                    rootView: SurveyWebView(
                        surveyType: surveyType
                    ).environmentObject(study)
                )
                surveyView.modalPresentationStyle = .fullScreen
                UIViewController.topViewController()?.present(surveyView, animated: true)
            }
        )
        
    }
    
    var studyDuration: TimeInterval? {
        
        if let study = study as? (any LongTerm) {
            return study.duration
        }
        
        return nil
        
    }
    
}

public struct DefaultStudyView: View {
    
    public var studyMetadata: StudyInformation
    public var studyDuration: TimeInterval?
    public var surveyType: SurveyType
    public var dismissStudy: () -> Void = { }
    public var primaryAction: () -> Void = { }
    
    public init(
        studyMetadata: StudyInformation,
        studyDuration: TimeInterval?,
        surveyType: SurveyType,
        dismissStudy: @escaping () -> Void,
        primaryAction: @escaping () -> Void
    ) {
        self.studyMetadata = studyMetadata
        self.surveyType = surveyType
        self.dismissStudy = dismissStudy
        self.primaryAction = primaryAction
    }
    
    public var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            
            HStack {
                
                Spacer()
                
                DismissButton(action: {
                    dismissStudy()
                })
                
            }
            
            if let image = studyMetadata.image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .mask(RoundedRectangle(cornerRadius: 12))
                        .padding(.vertical)
                    
                    if surveyType == .completion {
                        Color.black.opacity(0.2)
                        Text("✅")
                            .font(.largeTitle)
                            .scaleEffect(2)
                    }
                }
            }
            
            if surveyType == .introductory {
                
                Text(studyMetadata.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                
                Text(studyMetadata.subtitle)
                    .foregroundColor(.secondary)
                
            } else if surveyType == .mid {
                
                Text(studyMetadata.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                
                Text("Please fill out the mid-study survey now to help our scientific progress.")
                    .foregroundColor(.secondary)
                
            } else if surveyType == .completion {
                
                Text("Study Completion Survey")
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                
                if let duration = studyDuration {
                    
                    let studyDurationWeekCount = Int(duration / 604800.0)
                    
                    Text("Thanks a lot for participating in the study, the \(studyDurationWeekCount) weeks of participation are now completed. Please fill out one last 3 minute survey!")
                        .foregroundColor(.secondary)
                    
                } else {
                    
                    Text("Thanks a lot for participating in the study. Please fill out one last 3 minute survey!")
                        .foregroundColor(.secondary)
                    
                }
                
            }
            
            Button(surveyType == .introductory ? "Learn More" : "Complete") {
                primaryAction()
            }
            .buttonStyle(BigRoundedButtonStyle(backgroundColor: Color.accentColor, textColor: Color.white))
            .padding(.vertical)
        }
        
    }
    
}


#Preview {
    
    let study = DataDonationStudy(
        studyIdentifier: "empty",
        studyInformation: StudyInformation.init(
            title: "Study Inactive",
            subtitle: "Study has ended, participation not possible",
            contactEmail: "-",
            image: UIImage(
                named: "placeholder_header",
                in: .module,
                with: nil
            )!,
            detailInfos: nil
        ),
        uploadConfiguration: UploadConfiguration(
            fileSubmissionServer: URL(string: "https://example.org")!,
            uploadFrequency: 60 * 60 * 24,
            apiKey: "some-api-key"
        ),
        introductorySurveyURL: URL(
            string: "https://example.org"
        )!,
        participationIsPossible: false,
        introSurveyCompletionHandler: nil
    )
    
    List {
        
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(study)
        
    }
    
}
