//
//  GeneratedHeaderParameterDecodingMiddleware.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 04.05.26.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime

struct GeneratedHeaderParameterDecodingMiddleware {

    private let headerNames: [HTTPField.Name] = [
        "Participant-Identifier",
        "Participant-Public-Identifier",
        "Client-Version",
        "Client-Build",
        "Client-Platform",
        "Client-OS-Version",
        "Client-Device-Model",
        "Client-Timezone",
        "Client-Locale",
        "Client-Locales",
    ].compactMap { HTTPField.Name($0) }

}

extension GeneratedHeaderParameterDecodingMiddleware: ClientMiddleware {

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {

        var request = request

        for headerName in headerNames {
            guard let headerValue = request.headerFields[headerName],
                  let decodedHeaderValue = headerValue.removingPercentEncoding else {
                continue
            }

            request.headerFields[headerName] = decodedHeaderValue
        }

        return try await next(request, body, baseURL)

    }

}
