//
//  UploadError.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 01.05.26.
//


import Foundation
import OSLog
import OpenAPIRuntime
import OpenAPIURLSession

public enum UploadError: Error {

    case fileReadFailed(Error)
    case networkingError(Error)
    case missingClient

    case alreadyUploading

    case invalidResponse
    case httpStatus(Int)
    case serverRejected(String?)
}