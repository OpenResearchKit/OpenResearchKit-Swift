//
//  UploadConfiguration.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//


import Foundation

public struct UploadConfiguration {

    public let uploadFrequency: TimeInterval
    public let serverURL: URL
    public let apiKey: String?

    public init(serverURL: URL, uploadFrequency: TimeInterval, apiKey: String) {
        self.uploadFrequency = uploadFrequency
        self.serverURL = serverURL
        self.apiKey = apiKey
    }
    
    func isUploadDue(lastUpload: Date) -> Bool {
        if abs(lastUpload.timeIntervalSinceNow) > self.uploadFrequency {
            return true
        }
        return false
    }

}
