//
//  ThrowingButton.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import SwiftUI

struct ThrowingButton<Label: View>: View {
    
    let title: String
    let action: () throws -> Void
    
    @ViewBuilder let label: () -> Label
    
    @State private var errorMessage: String?
    
    var body: some View {
        
        Button(action: {
            do {
                try action()
            } catch {
                errorMessage = error.localizedDescription
            }
        }) {
            label()
        }
        .alert(String(localized: "Error", bundle: .module), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Okay", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        
    }
    
}

extension ThrowingButton where Label == Text {
    init(_ title: String, action: @escaping () throws -> Void) {
        self.title = title
        self.action = action
        self.label = { Text(title) }
    }
}
