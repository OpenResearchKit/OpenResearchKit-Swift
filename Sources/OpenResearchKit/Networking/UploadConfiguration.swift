//
//  UploadConfiguration.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//


import Foundation
import UIKit
import SwiftUI

public struct UploadConfiguration {
    
    public let fileSubmissionServer: URL
    public let uploadFrequency: TimeInterval
    public let apiKey: String
    
    public init(fileSubmissionServer: URL, uploadFrequency: TimeInterval, apiKey: String) {
        self.fileSubmissionServer = fileSubmissionServer
        self.uploadFrequency = uploadFrequency
        self.apiKey = apiKey
    }
    
    func isUploadDue(lastUpload: Date) -> Bool {
        if abs(lastUpload.timeIntervalSinceNow) > self.uploadFrequency {
            return true
        }
        return false
    }
    
}
