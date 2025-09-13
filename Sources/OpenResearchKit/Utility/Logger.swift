//
//  Logger.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 10.09.25.
//

import OSLog

extension Logger {
    
    public static let research: Logger = .init(subsystem: Bundle.main.bundleIdentifier!, category: "Research")
    
}
