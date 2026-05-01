//
//  StudyDataUploaderLiveIntegrationTests.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 01.05.26.
//

import Foundation
import XCTest

@testable import OpenResearchKit

final class StudyDataUploaderLiveIntegrationTests: XCTestCase {

    func testUploadStudyFolder_UploadsToLiveStudyAPIWhenEnabled() async throws {
        let config = try LiveUploadIntegrationConfiguration.loadFromEnvironment()
        let runIdentifier = UUID().uuidString
        let client = Client(baseURL: config.baseURL, apiKey: config.apiKey)
        let uploader = StudyDataUploader(client: client)
        let manager = StudyFileManager(uploader: uploader)
        let study = LiveUploadTestStudy.makeStudy(
            id: config.studyIdentifier,
            serverURL: config.baseURL,
            apiKey: config.apiKey
        )
        study.userIdentifier = "\(config.studyIdentifier)-integration-\(runIdentifier)"
        study.setPublicIdentifier("integration-\(runIdentifier)")
        addTeardownBlock {
            try? study.reset()
        }

        let file = try createUploadFile(
            study: study,
            timestamp: Self.uploadTimestamp(),
            name: "live-upload-\(runIdentifier).json",
            payload: Self.uploadPayload(runIdentifier: runIdentifier)
        )
        let batchDirectory = file.deletingLastPathComponent()

        try await manager.uploadStudyFolder(study: study)

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: batchDirectory.path))
        XCTAssertNotNil(study.lastSuccessfulUploadDate)
    }

    private static func uploadTimestamp(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }

    private static func uploadPayload(runIdentifier: String) throws -> Data {
        let payload: [String: String] = [
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "run_id": runIdentifier,
            "source": "OpenResearchKit live upload integration test",
        ]

        return try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    }

    private func createUploadFile(
        study: Study,
        timestamp: String,
        name: String,
        payload: Data
    ) throws -> URL {
        let file = study.studyDirectory(type: .upload)
            .appendingPathComponent(timestamp, isDirectory: true)
            .appendingPathComponent(name)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try payload.write(to: file)
        return file
    }

}

private struct LiveUploadIntegrationConfiguration {

    let baseURL: URL
    let apiKey: String
    let studyIdentifier: String

    static func loadFromEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> LiveUploadIntegrationConfiguration {
        guard environment["OPENRESEARCHKIT_RUN_LIVE_UPLOAD_TESTS"] == "1" else {
            throw XCTSkip("Set OPENRESEARCHKIT_RUN_LIVE_UPLOAD_TESTS=1 to run live upload integration tests.")
        }

        guard let apiKey = environment.nonEmptyValue(for: "OPENRESEARCHKIT_STUDY_API_KEY") else {
            throw XCTSkip("Set OPENRESEARCHKIT_STUDY_API_KEY to run live upload integration tests.")
        }

        guard let studyIdentifier = environment.nonEmptyValue(for: "OPENRESEARCHKIT_LIVE_UPLOAD_STUDY_IDENTIFIER") else {
            throw XCTSkip("Set OPENRESEARCHKIT_LIVE_UPLOAD_STUDY_IDENTIFIER to run live upload integration tests.")
        }

        guard let baseURLString = environment.nonEmptyValue(for: "OPENRESEARCHKIT_STUDY_API_BASE_URL") else {
            throw XCTSkip("Set OPENRESEARCHKIT_STUDY_API_BASE_URL to run live upload integration tests.")
        }

        guard let baseURL = URL(string: baseURLString), baseURL.scheme != nil, baseURL.host != nil else {
            throw LiveUploadIntegrationConfigurationError.invalidBaseURL(baseURLString)
        }

        return LiveUploadIntegrationConfiguration(
            baseURL: baseURL,
            apiKey: apiKey,
            studyIdentifier: studyIdentifier
        )
    }

}

private enum LiveUploadIntegrationConfigurationError: Error, CustomStringConvertible {

    case invalidBaseURL(String)

    var description: String {
        switch self {
            case .invalidBaseURL(let value):
                return "OPENRESEARCHKIT_STUDY_API_BASE_URL is not a valid absolute URL: \(value)"
        }
    }

}

private extension Dictionary where Key == String, Value == String {

    func nonEmptyValue(for key: String) -> String? {
        guard let value = self[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }

}

private final class LiveUploadTestStudy: DataDonationStudy {

    static func makeStudy(id: String, serverURL: URL, apiKey: String) -> LiveUploadTestStudy {
        LiveUploadTestStudy(
            studyIdentifier: id,
            studyInformation: StudyInformation(
                title: "Live Upload Integration Test",
                subtitle: "Live Upload Integration Test",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                serverURL: serverURL,
                uploadFrequency: 3600,
                apiKey: apiKey
            ),
            introductorySurveyURL: nil,
            participationIsPossible: true
        )
    }

}
