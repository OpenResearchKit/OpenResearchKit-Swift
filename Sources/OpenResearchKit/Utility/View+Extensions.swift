//
//  View+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//

import SwiftUI

public extension View {
    
    /// Wraps the view in `AnyView` for type erasure (e.g., when branches must return the same type).
    @inlinable
    func toAnyView() -> AnyView {
        AnyView(self)
    }
    
}
