//
//  UploadsData.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import OSLog

public protocol UploadsStudyData: GeneralStudy {
    
    var uploadConfiguration: UploadConfiguration { get }
    
    func uploadIfNecessary()
    
    func shouldUpload() -> Bool
    
    func appendNewJSONObjects(newObjects: [[String: JSONConvertible]])
    
    func studyDirectory(type: StudyDataDirectoryType) -> URL
    
}
