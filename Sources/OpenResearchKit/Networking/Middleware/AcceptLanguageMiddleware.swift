//
//  AcceptLanguageMiddleware.swift
//
//
//  Created by Lennart Fischer on 07.04.24.
//

import OpenAPIRuntime
import Foundation
import HTTPTypes

public struct AcceptLanguageMiddleware {

    /// The value for the `Accept-Language` header field.
    private let language: String?

    private let bundle: Bundle

    /// Creates a new middleware.
    /// - Parameters:
    ///   - bundle: The bundle used to infer the preferred localization when no override is provided.
    ///   - language: The explicit `Accept-Language` value.
    public init(bundle: Bundle = .main, overrideLanguage language: String? = nil) {
        self.bundle = bundle
        self.language = language
    }

}


extension AcceptLanguageMiddleware: ClientMiddleware {

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {

        var request = request
        let preferredLocale = bundle.preferredLocalizations.first ?? "en"

        // Adds the `Accept-Language` header field with the provided value.
        request.headerFields[.acceptLanguage] = language ?? preferredLocale

        return try await next(request, body, baseURL)

    }

}
