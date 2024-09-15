//
//  File.swift
//  
//
//  Created by Frederik Riedel on 13.01.23.
//

import Foundation
import SwiftUI

public struct StudyActiveDetailInfos: View {
    
    @EnvironmentObject var study: Study
    
    @State var showTerminationDialog = false
    
    @State var lastUploadDate: Date?
    @State var studyData: [ [String: Any] ] = []
    
    public var body: some View {
        List {
            
            if let image = study.universityLogo {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Section {
                if study.isActivelyRunning || isDebug {
                    if let detailInfos = study.detailInfos {
                        Text(detailInfos)
                    } else {
                        Text("You are currently participating in a scientific study to help make this app even better. If you have any questions, please contact us.")
                    }
                }
                
                Button("Contact \(study.contactEmail)") {
                    let email = "mailto:"
                    let emailformatted = email + study.contactEmail
                    guard let url = URL(string: emailformatted) else { return }
                    UIApplication.shared.open(url)
                }
            }
            
            Section {
                Text("Your anonymous participation id: `\(study.userIdentifier)`")
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = study.userIdentifier
                        } label: {
                            Label("Copy Participation ID", systemImage: "doc.on.doc")
                        }
                    }
                Text("Consent date: `\(study.userConsentDate?.description ?? "n/a")`")
                Text("End date: `\(study.studyEndDate?.description ?? "n/a")`")
            }
            
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
            
            
            Section {
                if #available(iOS 15.0, *) {
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
                } else {
                    // Fallback on earlier versions
                }
            }
            
        }
        .navigationBarTitle(study.title)
        .onAppear {
            self.lastUploadDate = study.lastSuccessfulUploadDate
            self.studyData = study.JSONFile
        }
    }
    
    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
