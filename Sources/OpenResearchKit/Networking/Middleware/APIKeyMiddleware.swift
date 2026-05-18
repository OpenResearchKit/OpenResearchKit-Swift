//
//  APIKeyMiddleware.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 30.04.26.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime

public struct APIKeyMiddleware {

    private let apiKeyGenerator: @Sendable () -> String

    public init(apiKey: String) {
        self.apiKeyGenerator = { apiKey }
    }
    
    public init(apiKeyGenerator: @escaping @Sendable () -> String) {
        self.apiKeyGenerator = apiKeyGenerator
    }

}

extension APIKeyMiddleware: ClientMiddleware {

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {

        var request = request

        if let headerName = HTTPField.Name("X-API-Key") {
            request.headerFields[headerName] = apiKeyGenerator()
        }

        return try await next(request, body, baseURL)

    }

}
