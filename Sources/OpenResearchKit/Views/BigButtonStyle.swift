//
//  BigButtonStyle.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 25.08.25.
//


import SafariServices
import SwiftUI
import UIKit

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

#Preview {
    
    Button(action: {}) {
        Text("Example Button")
    }
    .buttonStyle(
        BigButtonStyle(
            backgroundColor: Color.blue,
            textColor: Color.white
        )
    )
    .padding()
    
}
