//
//  RemoteEnrollmentService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.04.26.
//

import OSLog
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession


public class RemoteEnrollmentService: EnrollmentService {

    private let client: Client
    private let logger: Logger = Logger(subsystem: "org.openresearchkit", category: "Enrollment")

    public init(client: Client) {
        self.client = client
    }

    @available(*, deprecated, message: "Create a generated Client at app level and pass it to init(client:).")
    public convenience init(
        serverURL: URL,
        apiKey: String,
        transport: any ClientTransport = URLSessionTransport()
    ) {
        self.init(
            client: Client(
                baseURL: serverURL,
                apiKey: apiKey,
                transport: transport
            )
        )
    }

    @available(*, deprecated, message: "Use init(serverURL:apiKey:) or pass a generated Client to init(client:).")
    public convenience init(serverURL: URL) {
        self.init(serverURL: serverURL, apiKey: "")
    }

    public func enroll(study: Study) async throws {

        let response = try await client.enrollParticipant(
            path: Operations.EnrollParticipant.Input.Path(
                studyIdentifier: study.studyIdentifier
            ),
            body: Operations.EnrollParticipant.Input.Body.json(
                Components.Schemas.EnrollParticipantRequest(
                    participantIdentifier: study.userIdentifier,
                    participantPublicIdentifier: study.publicUserIdentifier
                )
            )
        )

        switch response {
            case .ok(let data):
                let enrolledAt = try data.body.json.participant.enrolledAt
                study.enrolledRemoteAt = enrolledAt
            case .notFound(let data):
                let message = try data.body.json.message
                self.logger.error("Failed with 404: \(message)")
            case .unprocessableContent(let data):
                let message = try data.body.json.message
                let errors = try data.body.json.errors
                self.logger.error("Failed with 422: \(message), \(errors.additionalProperties)")
            case .undocumented(let statusCode, let payload):
                self.logger.error("Failed with undocumented code \(statusCode): \(String(describing: payload.body))")
        }

    }

}
