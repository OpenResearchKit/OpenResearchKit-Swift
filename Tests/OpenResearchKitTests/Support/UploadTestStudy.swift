//
//  UploadTestStudy.swift
//  OpenResearchKit
//

import Foundation

@testable import OpenResearchKit

final class UploadTestStudy: DataDonationStudy {

    private(set) var didFinishAllPendingUploadsCallCount = 0

    override func didFinishAllPendingUploads() async throws {
        didFinishAllPendingUploadsCallCount += 1
    }

    static func makeStudy(id: String = UUID().uuidString) -> UploadTestStudy {
        UploadTestStudy(
            studyIdentifier: id,
            studyInformation: StudyInformation(
                title: "Upload Test",
                subtitle: "Upload Test",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                serverURL: URL(string: "https://example.org")!,
                uploadFrequency: 3600,
                apiKey: ""
            ),
            introductorySurveyURL: nil,
            participationIsPossible: true
        )
    }
}
