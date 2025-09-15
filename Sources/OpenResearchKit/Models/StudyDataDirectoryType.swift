//
//  StudyDataDirectoryType.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//


import Foundation

public enum StudyDataDirectoryType: String {
    
    /// Used for uploading the data in that directory
    case upload = "upload"
    
    /// Used for keeping a local files for a study meant to be altered during runtime
    case working = "working"
    
    var directoryName: String {
        return self.rawValue
    }
    
}
