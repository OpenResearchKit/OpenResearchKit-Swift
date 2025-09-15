//
//  StudyStatusBadge.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import SwiftUI

struct StudyStatusBadge: View {
    
    @State private var state: ViewState = .loading
    
    let study: Study
    
    init(study: Study) {
        self.study = study
    }
    
    var body: some View {
        
        Group {
            
            switch state {
                    
                case .loading:
                    
                    StatusBadge(studyStatus: .mutedStyle(text: "Loading…"))
                        .redacted(reason: .placeholder)
                    
                case .loaded(let studyStatus):
                    StatusBadge(studyStatus: studyStatus)
                    
                case .error:
                    StatusBadge(studyStatus: .errorStyle(text: "\(Image(systemName: "exclamationmark.octagon.fill"))"))
                    
            }
            
        }
        .task {
            
            self.state = .loading
            
            do {
                let status = try await study.currentDisplayStatus()
                self.state = .loaded(status)
            } catch {
                self.state = .error
            }
            
        }
        
    }
    
    private enum ViewState {
        case loading
        case loaded(StudyStatus)
        case error
    }
    
}

