//
//  RemoteStudyConfigurationService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 02.07.26.
//

import Foundation
import OSLog

public struct RemoteStudyConfigurationService: StudyConfigurationService {

    public init() {

    }

    public func isAvailable(for study: Study) async throws -> Bool? {
        let client = Client(
            baseURL: study.uploadConfiguration.serverURL,
            apiKey: study.uploadConfiguration.apiKey
        )
        let response = try await client.showStudyConfiguration(
            path: Operations.ShowStudyConfiguration.Input.Path(
                studyIdentifier: study.studyIdentifier
            )
        )

        switch response {
        case .ok(let data):
            return try data.body.json.data.isAvailable
        case .notFound(_):
            Logger.research.info("No remote recommendation configuration found for study \(study.studyIdentifier, privacy: .public). Falling back to local recommendation rules.")
            return nil
        case .undocumented(let statusCode, _):
            Logger.research.error("Unexpected recommendation configuration response for study \(study.studyIdentifier, privacy: .public): \(statusCode).")
            throw URLError(.badServerResponse)
        }
    }

}
