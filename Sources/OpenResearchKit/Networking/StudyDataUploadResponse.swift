//
//  StudyDataUploadResponse.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 12.09.25.
//

struct StudyDataUploadResponse: Codable {
    
    struct Results: Codable {
        let success: Bool
    }
    
    let result: Results
    
    enum CodingKeys: String, CodingKey {
        case result = "result"
    }
    
}
