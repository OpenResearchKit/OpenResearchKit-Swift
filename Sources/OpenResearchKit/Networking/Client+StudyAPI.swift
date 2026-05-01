//
//  Client+StudyAPI.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 30.04.26.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public extension Client {

    init(
        baseURL serverURL: URL,
        apiKey: String?,
        transport: any ClientTransport = URLSessionTransport()
    ) {
        self.init(
            serverURL: serverURL,
            configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
            transport: transport,
            middlewares: [
                AcceptLanguageMiddleware(),
                APIKeyMiddleware(apiKeyGenerator: {
                    apiKey ?? ""
                }),
            ]
        )
    }
    
}
