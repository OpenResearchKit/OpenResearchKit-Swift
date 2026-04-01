//
//  StudyStatus.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import Foundation
import SwiftUI

public struct StudyStatus {
    
    let text: LocalizedStringKey
    let backgroundColor: Color
    let foregroundColor: Color
    
    public init(text: LocalizedStringKey, backgroundColor: Color, foregroundColor: Color) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    public static func successStyle(text: LocalizedStringKey) -> Self {
        return StudyStatus(
            text: text,
            backgroundColor: .green,
            foregroundColor: .white
        )
    }
    
    public static func alertStyle(text: LocalizedStringKey) -> Self {
        return StudyStatus(
            text: text,
            backgroundColor: .yellow,
            foregroundColor: .black
        )
    }
    
    public static func mutedStyle(text: LocalizedStringKey) -> Self {
        return StudyStatus(
            text: text,
            backgroundColor: Color(UIColor.secondarySystemFill),
            foregroundColor: Color(UIColor.label)
        )
    }
    
    public static func errorStyle(text: LocalizedStringKey) -> Self {
        return StudyStatus(
            text: text,
            backgroundColor: .red,
            foregroundColor: .white
        )
    }
    
}
