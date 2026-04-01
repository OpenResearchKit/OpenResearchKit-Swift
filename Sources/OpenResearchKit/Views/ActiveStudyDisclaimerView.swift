//
//  ActiveStudyDisclaimerView.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 21.01.26.
//

import SwiftUI

public struct ActiveStudyDisclaimerView<Background: View>: View {
    
    @State var showSheet = false
    
    @EnvironmentObject var study: Study
    
    public let foregroundColor: Color
    public let background: () -> Background
    
    public init(foregroundColor: Color, @ViewBuilder background: @escaping () -> Background) {
        self.foregroundColor = foregroundColor
        self.background = background
    }
    
    public var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                
                Image(systemName: "info.circle")
                
                Text("Active Study Participation", bundle: .module)
                    .font(.body.weight(.semibold))
                
            }
            .padding(.bottom, 2)
            
            Text("You are currently participating in a scientific study. This may have implications on how one sec works or may disable certain features.", bundle: .module)
                .font(.callout)
                .padding(.bottom, 4)
            
            Button(action: {
                showSheet = true
            }) {
                Text("\(String(localized: "Learn more", bundle: .module)) \(Image(systemName: "chevron.right"))")
                    .font(.body.weight(.medium))
            }
            
        }
        .foregroundColor(foregroundColor)
        .listRowBackground(background())
        .clipped()
        .sheet(isPresented: $showSheet) {
            NavigationView {
                StudyDetailInfoScreen(study: study)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            closeButton
                        }
                    }
            }
            .interactiveDismissDisabled()
        }
        
    }
    
    private var closeButton: AnyView {
        if #available(iOS 26.0, *) {
            Button(role: .close) {
                showSheet = false
            }.toAnyView()
        } else {
            Button(String(localized: "Close", bundle: .module)) {
                showSheet = false
            }.toAnyView()
        }
    }
    
}

#Preview {
    
    List {
        
        ActiveStudyDisclaimerView(
            foregroundColor: .white
        ) {
            Color.cyan
        }
        
    }
    
}
