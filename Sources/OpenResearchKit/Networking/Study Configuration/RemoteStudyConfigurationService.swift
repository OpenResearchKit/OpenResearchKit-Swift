//
//  RemoteStudyConfigurationService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 02.07.26.
//

import Foundation
import OSLog

public struct RemoteStudyConfigurationService: StudyConfigurationService {

    private let clientFactory: (UploadConfiguration) -> any APIProtocol

    /// Calls the factory for each check with the study's current upload configuration.
    public init(
        clientFactory: @escaping (UploadConfiguration) -> any APIProtocol = {
            Client(baseURL: $0.serverURL, apiKey: $0.apiKey)
        }
    ) {
        self.clientFactory = clientFactory
    }

    /// Uses the same generated client or API mock for all study configuration checks.
    public init(client: any APIProtocol) {
        self.clientFactory = { _ in client }
    }

    public func isAvailable(for study: Study) async throws -> Bool? {
        let client = clientFactory(study.uploadConfiguration)
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
