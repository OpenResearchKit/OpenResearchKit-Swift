//
//  TimeTraveling.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 16.09.25.
//

import Foundation

public protocol DateGenerator {
    
    func generate() -> Date
    
}

class TimeTraveler: DateGenerator {
    
    private var date = Date()
    
    func travel(by timeInterval: TimeInterval) {
        date = date.addingTimeInterval(timeInterval)
    }
    
    func generate() -> Date {
        return date
    }
    
}

public class DefaultDateGenerator: DateGenerator {
    
    public func generate() -> Date {
        return Date()
    }
    
}
