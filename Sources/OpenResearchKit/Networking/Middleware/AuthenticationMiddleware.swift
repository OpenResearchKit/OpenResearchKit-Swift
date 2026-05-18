//
//  AuthenticationMiddleware.swift
//
//
//  Created by Lennart Fischer on 07.04.24.
//

import OpenAPIRuntime
import Foundation
import HTTPTypes

/// A client middleware that injects a token into the `Authorization` header field of the request.
package struct AuthenticationMiddleware {
    
    /// The value for the `Authorization` header field.
    private let tokenLoader: @Sendable () -> String?
    
    /// Creates a new middleware.
    /// - Parameter value: The value for the `Authorization` header field.
    package init(tokenLoader: @Sendable @escaping () -> String?) {
        self.tokenLoader = tokenLoader
    }
}

extension AuthenticationMiddleware: ClientMiddleware {
    
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        
        var request = request
        
        // Adds the `Authorization` header field with the provided value.
        if let token = tokenLoader() {
            request.headerFields[.authorization] = "Bearer \(token)"
        }
        
        return try await next(request, body, baseURL)
    }
    
}
