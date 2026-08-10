//
//  StudyFileManagerPendingUploadsTests.swift
//  OpenResearchKit
//

import Foundation
import Testing

@testable import OpenResearchKit

@Test("Finishing pending uploads ignores empty directories and hidden files")
func didFinishAllPendingUploadsIgnoresEmptyDirectoriesAndHiddenFiles() async throws {
    let study = UploadTestStudy.makeStudy(id: "PendingUploadsTest-\(UUID().uuidString)")
    let uploadDirectory = study.studyDirectory(type: .upload)
    let studyDirectory = uploadDirectory.deletingLastPathComponent()
    defer {
        try? FileManager.default.removeItem(at: studyDirectory)
    }

    let batchDirectory = uploadDirectory.appendingPathComponent("20260428_120000", isDirectory: true)
    let emptyNestedDirectory = batchDirectory.appendingPathComponent("empty", isDirectory: true)
    try FileManager.default.createDirectory(at: emptyNestedDirectory, withIntermediateDirectories: true)
    try Data("metadata".utf8).write(to: batchDirectory.appendingPathComponent(".metadata"))

    try await study.studyFileManager.uploadStudyFolder(study: study, deleteEmptyDirectories: false)

    #expect(FileManager.default.fileExists(atPath: emptyNestedDirectory.path))
    #expect(study.didFinishAllPendingUploadsCallCount == 1)
}
