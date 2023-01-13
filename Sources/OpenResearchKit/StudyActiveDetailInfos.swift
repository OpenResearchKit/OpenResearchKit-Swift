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
    
    public var body: some View {
        List {
            Section {
                if study.isActivelyRunning {
                    Text("You are currently participating in a scientific study to help make one sec even better. If you have any questions, please contact us.")
                }
                
                Button("Contact \(study.contactEmail)") {
                    let email = "mailto://"
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
}
