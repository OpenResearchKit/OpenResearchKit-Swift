//
//  Signal.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 29.09.25.
//

import Foundation

public struct Signal: Encodable {
    
    public let studyIdentifier: String
    public let userIdentifier: String
    public let type: String
    public let payload: [String: String]
    
    public init(studyIdentifier: String, userIdentifier: String, type: String, payload: [String : String] = [:]) {
        self.studyIdentifier = studyIdentifier
        self.userIdentifier = userIdentifier
        self.type = type
        self.payload = payload
    }
    
    enum CodingKeys: String, CodingKey {
        case studyIdentifier = "study_identifier"
        case userIdentifier = "user_identifier"
        case type = "type"
        case payload = "payload"
    }
    
}
