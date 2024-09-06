//
//  File.swift
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
        
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Spacer()
                Button {
                    study.isDismissedByUser = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.secondary)
                        .opacity(0.75)
                }
            }
            
            if let image = study.universityLogo {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .mask(RoundedRectangle(cornerRadius: 12))
                    .padding(.vertical)
            }
            if surveyType == .introductory {
                Text(study.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                Text(study.subtitle)
                    .foregroundColor(.secondary)
            } else if surveyType == .mid {
                Text(study.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                Text("Please fill out the mid-study survey now to help our scientific progress.")
                    .foregroundColor(.secondary)
            } else {
                Text(study.title)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .bold()
                Text("Thanks a lot for participating in the study, the 6 weeks of participation are now completed. Please fill out one last 3 minute survey!")
                    .foregroundColor(.secondary)
            }
            
            Button(surveyType == .introductory ? "Learn more" : "Complete") {
                let surveyView = UIHostingController(rootView: SurveyWebView(surveyType: surveyType).environmentObject(study))
                surveyView.modalPresentationStyle = .fullScreen
                UIViewController.topViewController()?.present(surveyView, animated: true)
            }
            .buttonStyle(BigButtonStyle(backgroundColor: Color.accentColor.opacity(0.22), textColor: Color.accentColor))
            .padding(.vertical)
        }
    }
}


struct BigButtonStyle: ButtonStyle {
    
    let backgroundColor: Color
    let textColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        
        HStack {
            Spacer()
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundColor(textColor)
            Spacer()
        }
        .padding(16)
        .background(backgroundColor)
        .mask(RoundedRectangle(cornerRadius: 12))
        .opacity(configuration.isPressed ? 0.6 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
