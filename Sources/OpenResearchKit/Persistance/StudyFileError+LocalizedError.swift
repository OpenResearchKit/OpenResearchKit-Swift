//
//  StudyFileError+LocalizedError.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 26.07.26.
//

import Foundation

extension StudyFileError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .cannotCreateZipArchive(let sourceDirectory, let reason):
            return "Could not create a ZIP archive for \(sourceDirectory.lastPathComponent): \(reason)"
        case .duplicateUploadFileNames(let timestamp, let fileNames):
            return "Upload batch \(timestamp) contains duplicate file names: \(fileNames.joined(separator: ", "))."
        case .flatUploadFileFound(let file):
            return "Found an upload file outside a timestamped upload batch: \(file.lastPathComponent)."
        case .invalidUploadBatchDirectory(let directory):
            return "Invalid upload batch directory: \(directory.lastPathComponent)."
        default:
            return nil
        }
    }

}
