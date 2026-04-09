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
                StudyPresenter.show(study: study, surveyType: surveyType)
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
            
            if let image = studyMetadata.image?() {
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
                
                ScientificStudyLabel()
                
                Text(studyMetadata.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                
                Text(studyMetadata.description)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
            } else if surveyType == .mid {
                
                ScientificStudyLabel()
                
                Text(studyMetadata.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                
                Text("Please fill out the mid-study survey now to help our scientific progress.", bundle: .module)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
            } else if surveyType == .completion {
                
                Text("Study Completion Survey")
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                
                if let duration = studyDuration {
                    
                    let studyDurationWeekCount = Int(duration / 604800.0)
                    
                    Text("Thanks a lot for participating in the study, the \(studyDurationWeekCount) weeks of participation are now completed. Please fill out one last 3 minute survey!", bundle: .module)
                        .foregroundColor(.secondary)
                    
                } else {
                    
                    Text("Thanks a lot for participating in the study. Please fill out one last 3 minute survey!", bundle: .module)
                        .foregroundColor(.secondary)
                    
                }
                
            }
            
            Button(action: {
                primaryAction()
            }) {
                Text(surveyType == .introductory ? "Learn More" : "Complete", bundle: .module)
            }
            .buttonStyle(
                BigRoundedButtonStyle(
                    backgroundColor: Color.accentColor,
                    textColor: Color.white
                )
            )
            .padding(.vertical)
            
        }
        
    }
    
}

struct ScientificStudyLabel: View {
    
    var body: some View {
        
        Text("Scientific Study", bundle: .module)
            .font(.footnote.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.tint)
        
    }
    
}

fileprivate let study = DataDonationStudy(
    studyIdentifier: "empty",
    studyInformation: StudyInformation.init(
        title: "Example Research Project",
        subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        contactEmail: "-",
        image: UIImage(
            named: "placeholder_header",
            in: .module,
            with: nil
        )!
    ),
    uploadConfiguration: UploadConfiguration(
        fileSubmissionServer: URL(string: "https://example.org")!,
        uploadFrequency: 60 * 60 * 24,
        apiKey: "some-api-key"
    ),
    introductorySurveyURL: URL(
        string: "https://example.org"
    )!,
    participationIsPossible: false
)

#Preview {
    
    List {
        
        Section {
            StudyBannerInvitation(surveyType: .introductory)
                .environmentObject(study as Study)
        }
        
        Section {
            StudyBannerInvitation(surveyType: .mid)
                .environmentObject(study as Study)
        }
        
        Section {
            StudyBannerInvitation(surveyType: .completion)
                .environmentObject(study as Study)
        }
        
    }
    
}

#Preview {
    
    List {
        
        StudyBannerInvitation(surveyType: .introductory)
            .environmentObject(study as Study)
        
    }
    .preferredColorScheme(.dark)
    
}
