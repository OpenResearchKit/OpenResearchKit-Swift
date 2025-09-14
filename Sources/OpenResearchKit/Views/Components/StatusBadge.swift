//
//  StatusBadge.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import SwiftUI

struct StatusBadge: View {
    
    let text: LocalizedStringKey
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(
        text: LocalizedStringKey,
        backgroundColor: Color,
        foregroundColor: Color
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    init(
        studyStatus: StudyStatus
    ) {
        self.text = studyStatus.text
        self.backgroundColor = studyStatus.backgroundColor
        self.foregroundColor = studyStatus.foregroundColor
    }
    
    var body: some View {
        
        Text(text)
            .font(.footnote)
            .fontWeight(.medium)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        
    }
    
}

#Preview {
    StatusBadge(
        text: "Active",
        backgroundColor: .green,
        foregroundColor: .white
    )
}
