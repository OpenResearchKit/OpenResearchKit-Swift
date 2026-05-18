//
//  Date+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

extension Date {
    
    var isInFuture: Bool {
        return self.timeIntervalSinceNow > 0
    }
    
}
