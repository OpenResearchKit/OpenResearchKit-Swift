//
//  StudyDataUploadResponse.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 12.09.25.
//

struct StudyDataUploadResponse: Codable {
    
    struct Results: Codable {
        
        let success: Bool
        
        init(from decoder: any Decoder) throws {
            
            let container: KeyedDecodingContainer<StudyDataUploadResponse.Results.CodingKeys> = try decoder.container(keyedBy: StudyDataUploadResponse.Results.CodingKeys.self)
            
            if let success = try? container.decode(Bool.self, forKey: StudyDataUploadResponse.Results.CodingKeys.success) {
                self.success = success
            } else {
                let decodedString = try container.decode(String.self, forKey: StudyDataUploadResponse.Results.CodingKeys.success)
                self.success = decodedString == "true"
            }
            
        }
        
    }
    
    let result: Results
    
    enum CodingKeys: String, CodingKey {
        case result = "result"
    }
    
}
