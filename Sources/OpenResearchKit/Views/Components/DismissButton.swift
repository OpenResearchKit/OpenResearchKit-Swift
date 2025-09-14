//
//  DismissButton.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 09.09.25.
//

import SwiftUI

public struct DismissButton: View {
    
    private let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        
        Button {
            action()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.secondary)
                .opacity(0.75)
        }
        
    }
    
}

#Preview {
    DismissButton(action: {})
}
