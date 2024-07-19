//
//  File.swift
//  
//
//  Created by Frederik Riedel on 13.01.23.
//

import Foundation
import SwiftUI
import FredKit

public struct StudyActiveDetailInfos: View {
    
    @EnvironmentObject var study: Study
    
    @State var showTerminationDialog = false
    
    public var body: some View {
        List {
            
            Section {
                Image(uiImage: study.universityLogo)
                    .resizable()
                    .scaledToFit()
            }
            
            Section {
                if study.isActivelyRunning || isDebug {
                    Text("You are currently participating in a scientific study to help make this app even better. If you have any questions, please contact us.")
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
                    Text("Contributed")
                    Spacer()
                    Text("\(study.JSONFile.count) data points")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Last upload")
                    Spacer()
                    if let date = study.lastSuccessfulUploadDate {
                        Text(date.humanReadableDateAndTimeString)
                            .foregroundColor(.secondary)
                    } else {
                        Text("–")
                            .foregroundColor(.secondary)
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
    }
    
    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
