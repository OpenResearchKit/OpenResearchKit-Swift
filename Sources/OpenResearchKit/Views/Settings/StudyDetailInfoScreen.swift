//
//  StudyDetailInfoScreen.swift
//  
//
//  Created by Frederik Riedel on 13.01.23.
//

import Foundation
import SwiftUI

public struct StudyDetailInfoScreen: View {
    
    @EnvironmentObject var activeStudy: Study
    @Environment(\.dismiss) var dismiss
    
    let study: Study
    
    public init(study: Study) {
        self.study = study
    }
    
    @State var showTerminationDialog = false
    
    @State var lastUploadDate: Date?
    @State var studyData: [ [String: Any] ] = []
    
    public var body: some View {
        
        List {
            
            if #available(iOS 26.0, *) {
                header()
                    .listRowInsets(.all, 0)
            } else {
                header()
            }
            
            info()
            
            studyStatus()
            
            if study.hasUserGivenConsent {
                metadata()
                
                data()
            }
            
            actions()
            
        }
//        .navigationBarTitle(study.studyInformation.title)
        .task {
            self.lastUploadDate = study.lastSuccessfulUploadDate
            self.studyData = study.JSONFile
        }
        
    }
    
    @ViewBuilder
    private func header() -> some View {
        
        if let image = study.studyInformation.image {
            Section {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        
    }
    
    @ViewBuilder
    private func info() -> some View {
        
        Section(header: Text("Information", bundle: .module)) {
            
            VStack(alignment: .leading) {
                
                Text(study.studyInformation.title)
                    .fontWeight(.medium)
                
                Text(study.studyInformation.description)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                
                HStack {
                    
                    Image(systemName: "envelope")
                        .imageScale(.small)
                    
                    Text(study.studyInformation.contactEmail)
                    
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = study.studyInformation.contactEmail
                    } label: {
                        Label(String(localized: "Copy Email", bundle: .module), systemImage: "doc.on.doc")
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Button(action: openEmail) {
                Text("Contact Us", bundle: .module)
            }
            
        }
        
    }
    
    @ViewBuilder
    private func studyStatus() -> some View {
        
        Section(header: Text("Status")) {
            
            HStack {
                
                Text("Current status", bundle: .module)
                
                Spacer()
                
                StudyStatusBadge(study: study)
                
            }
            
            if let study = study as? LongTermStudy {
                
                if study.isActiveStudyPeriod {
                    
                    Text("You are currently participating in this study to help make this app even better. If you have any questions, please contact us.", bundle: .module)
                    
                }
                
            }
            
        }
        
    }
    
    @ViewBuilder
    private func metadata() -> some View {
        
        Section(footer: Text("Your anonymous participation id will be used once you explicitly consented into participating in the study.", bundle: .module)) {
            
            MetadataRow(title: "Anonymous participation id", content: "`\(study.userIdentifier)`")
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = study.userIdentifier
                    } label: {
                        Label("Copy Participation ID", systemImage: "doc.on.doc")
                    }
                }
            
            MetadataRow(title: "Consent date", content: "`\(study.userConsentDate?.description ?? "n/a")`")
            MetadataRow(title: "End date", content: "`\(study.userConsentDate?.description ?? "n/a")`")
            
        }
        
    }
    
    @ViewBuilder
    private func data() -> some View {
        
        Section {
            HStack {
                Text("Collected")
                Spacer()
                Text("\(self.studyData.count) data points")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Last upload")
                Spacer()
                if let date = self.lastUploadDate {
                    Text(date.description)
                        .foregroundColor(.secondary)
                } else {
                    Text("–")
                        .foregroundColor(.secondary)
                }
                
            }
            
            NavigationLink("View Data") {
                List {
                    ForEach(Array(self.studyData.enumerated()), id: \.offset) { item in
                        Text(item.element.description)
                    }
                }
            }
        }
        
    }
    
    @ViewBuilder
    private func actions() -> some View {
        
        Section {
            
            if !study.hasUserGivenConsent {
                
                Button("Start participation") {
                    StudyPresenter.show(study: study, surveyType: .introductory)
                }
                
            }
            
        }
        
        Section {
            if study.shouldShowTerminationButton {
                Button("Terminate participation") {
                    self.showTerminationDialog = true
                }
                .confirmationDialog("Would you like to end participation in the scientific study?", isPresented: $showTerminationDialog) {
                    Button("Terminate", role: .destructive) {
                        study.terminateParticipationImmediately()
                    }
                    
                    Button("Continue Participating", role: .none) {
                        // nothing
                    }
                }
            }
        }
        
        if Bundle.main.isInDebugMode || Bundle.main.isOnTestFlight {
            Section {
                
                ThrowingButton("Reset study data") {
                    try study.reset()
                    dismiss()
                }
                .foregroundStyle(.red)
                
            }
        }
        
    }
    
    // MARK: - Actions -
    
    private func openEmail() {
        
        let email = "mailto:"
        let emailformatted = email + study.studyInformation.contactEmail
        guard let url = URL(string: emailformatted) else { return }
        UIApplication.shared.open(url)
        
    }
    
}

struct MetadataRow: View {
    
    var title: LocalizedStringKey
    var content: LocalizedStringKey
    
    var body: some View {
        
        if #available(iOS 16.0, *) {
            LabeledContent(title) {
                Text(content)
            }
        } else {
            Text(title) + Text(": ") + Text(content)
        }
        
    }
    
}
