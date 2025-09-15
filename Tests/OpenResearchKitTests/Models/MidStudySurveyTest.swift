//
//  MidStudySurveyTest.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

class MidStudySurveyTest: XCTestCase {
    
    func testMidStudySurveyInitialization() {
        
        let url = URL(string: "https://example.com/mid-survey")!
        let timeInterval: TimeInterval = 3600  // 1 hour
        
        let midSurvey = MidStudySurvey(showAfter: timeInterval, url: url)
        
        XCTAssertEqual(midSurvey.showAfter, timeInterval)
        XCTAssertEqual(midSurvey.url, url)
        
    }
    
}
