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
    
}

struct DefaultStudyView: View {
    
    var studyMetadata: StudyInformation
    var surveyType: SurveyType
    var dismissStudy: () -> Void = { }
    var primaryAction: () -> Void = { }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            
            HStack {
                
                Spacer()
                
                Button {
                    dismissStudy()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.secondary)
                        .opacity(0.75)
                }
                
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
                
                if let duration = studyMetadata.duration {
                    
                    let studyDurationWeekCount = Int(duration / 604800.0)
                    
                    Text("Thanks a lot for participating in the study, the \(studyDurationWeekCount) weeks of participation are now completed. Please fill out one last 3 minute survey!")
                        .foregroundColor(.secondary)
                    
                } else {
                    
                    Text("Thanks a lot for participating in the study. Please fill out one last 3 minute survey!")
                        .foregroundColor(.secondary)
                    
                }
                
            }
            
            Button(surveyType == .introductory ? "Learn more" : "Complete") {
                primaryAction()
            }
            .buttonStyle(BigButtonStyle(backgroundColor: Color.accentColor.opacity(0.22), textColor: Color.accentColor))
            .padding(.vertical)
        }
        
    }
    
}


#Preview {
    
    let study = Study(
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
            duration: 60 * 60 * 24 * 7,
            detailInfos: nil
        ),
        introductorySurveyURL: URL(
            string: "https://oslopsych.az1.qualtrics.com/jfe/form/SV_3woeKVMUpQsUBwy"
        )!,
        concludingSurveyURL: URL(
            string: "https://oslopsych.az1.qualtrics.com/jfe/form/SV_73335RGCTBsrl7E"
        )!,
        fileSubmissionServer: URL(
            string: "https://mknztlfet6msiped4d5iuixssy0iekda.lambda-url.eu-central-1.on.aws"
        )!,
        apiKey: "0c549544-a6ba-4f57-b8bc-76d84dd5dae5",
        uploadFrequency: 7 * 60 * 60 * 24,
        participationIsPossible: false,
        introSurveyCompletionHandler: { parameters, study in
            // not necessary
        }
    )
    
    List {
        
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(study)
        
    }
    
}
