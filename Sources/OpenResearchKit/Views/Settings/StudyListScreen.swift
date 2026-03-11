//
//  StudyListScreen.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import SwiftUI
import UIKit

public struct StudyListScreen: View {
    
    private var activeStudy: Study?
    
    private var availableStudies: [Study]
    private var participatedStudies: [Study]
    
    public init(
        activeStudy: Study?,
        availableStudies: [Study],
        participatedStudies: [Study]
    ) {
        
        self.activeStudy = activeStudy
        self.availableStudies = availableStudies
        self.participatedStudies = participatedStudies
    }
    
    public var body: some View {
        
        List {
            
            if let activeStudy {
                
                Section(header: Text("Active")) {
                    StudyRow(study: activeStudy)
                }
                
            }
            
            if !availableStudies.isEmpty {
                Section(header: Text("Available for you")) {
                    
                    if activeStudy == nil {
                        
                        ForEach(availableStudies, id: \.studyIdentifier) { study in
                            StudyRow(study: study)
                        }
                        
                    } else {
                        
                        Text("You cannot participate in another study while already being enrolled in a study.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                    }
                    
                }
            }
            
            Section(header: Text("Previous participations")) {
                
                if participatedStudies.isEmpty {
                    Text("You have not participated in any studies yet.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                ForEach(participatedStudies, id: \.studyIdentifier) { study in
                    StudyRow(study: study)
                }
                
            }
            
        }
        .navigationTitle("Studies")
        
    }
    
}

public struct StudyRow: View {
    
    private let study: Study
    
    public init(study: Study) {
        self.study = study
    }
    
    public var body: some View {
        
        NavigationLink {
            StudyDetailInfoScreen(study: study)
        } label: {
            
            HStack {
                
                Text(study.studyInformation.title)
                
                Spacer()
                
                StudyStatusBadge(study: study)
                
            }
            
        }

        
    }
    
}

#Preview {
    
    let active = DataDonationStudy(
        studyIdentifier: "stanford-health-2025",
        studyInformation: StudyInformation(
            title: "Stanford study on mental & physical health",
            subtitle: "Participate in a research study together with Stanford University to understand how your social media use affects your mental health & physical fitness.",
            contactEmail: "digitalhealthresearch@stanford.edu",
            image: UIImage(
                named: "placeholder_header",
                in: .module,
                with: nil
            ),
        ),
        uploadConfiguration: .init(
            fileSubmissionServer: URL(string: "https://example.org")!,
            uploadFrequency: 0,
            apiKey: ""
        ),
        introductorySurveyURL: URL(string: "https://one-sec.app/placeholder-survey"),
        participationIsPossible: true,
        introSurveyCompletionHandler: nil
    )
    
    
    StudyListScreen(activeStudy: active, availableStudies: [], participatedStudies: [])
    
}
