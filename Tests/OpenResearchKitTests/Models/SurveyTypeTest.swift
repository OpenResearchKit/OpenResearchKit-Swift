//
//  SurveyTypeTest.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import XCTest

@testable import OpenResearchKit

class SurveyTypeTest: XCTestCase {
    
    func testSurveyTypeHasThreeTypes() {
        
        XCTAssertEqual(SurveyType.allCases.count, 3)
        
    }
    
}
