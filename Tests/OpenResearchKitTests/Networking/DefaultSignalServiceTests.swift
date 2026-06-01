//
//  DefaultSignalServiceTests.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 01.06.26.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import XCTest

@testable import OpenResearchKit

final class DefaultSignalServiceTests: XCTestCase {
    
    func testSend_UsesGeneratedV2RequestWithHeadersAndGenericSignalBody() async throws {
        let state = RecordingSignalTransportState(responseStatus: .created)
        let service = DefaultSignalService(client: makeClient(state: state))
        
        try await service.send(
            signal: Signal(
                studyIdentifier: "study-123",
                userIdentifier: "study-123-user",
                publicUserIdentifier: "participant-123",
                type: "completedHealthExportUpload",
                payload: [
                    "status": "completed"
                ]
            )
        )
        
        let requests = await state.requests
        let recordedRequest = try XCTUnwrap(requests.first)
        let body = try XCTUnwrap(recordedRequest.body)
        let bodyObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        let dataObject = try XCTUnwrap(bodyObject["data"] as? [String: Any])
        
        XCTAssertEqual(recordedRequest.operationID, Operations.StoreStudySignal.id)
        XCTAssertEqual(recordedRequest.baseURL, URL(string: "https://research.example.com")!)
        XCTAssertEqual(recordedRequest.request.path, "/api/v2/studies/study-123/signals")
        XCTAssertEqual(recordedRequest.request.headerFields[HTTPField.Name("Participant-Identifier")!], "study-123-user")
        XCTAssertEqual(recordedRequest.request.headerFields[HTTPField.Name("Participant-Public-Identifier")!], "participant-123")
        XCTAssertEqual(bodyObject["type"] as? String, "completedHealthExportUpload")
        XCTAssertEqual(dataObject["status"] as? String, "completed")
    }
    
    func testSend_OmitsPublicParticipantIdentifierWhenSignalDoesNotProvideOne() async throws {
        let state = RecordingSignalTransportState(responseStatus: .created)
        let service = DefaultSignalService(client: makeClient(state: state))
        
        try await service.send(
            signal: Signal(
                studyIdentifier: "study-123",
                userIdentifier: "study-123-user",
                type: "completedHealthExportUpload"
            )
        )
        
        let requests = await state.requests
        let recordedRequest = try XCTUnwrap(requests.first)
        
        XCTAssertNil(recordedRequest.request.headerFields[HTTPField.Name("Participant-Public-Identifier")!])
    }
    
    func testSend_ThrowsNotFoundError() async throws {
        let state = RecordingSignalTransportState(
            responseStatus: .notFound,
            responseBody: #"{"message":"Study not found."}"#
        )
        let service = DefaultSignalService(client: makeClient(state: state))
        
        do {
            try await service.send(signal: makeSignal())
            XCTFail("Expected StoreSignalError.notFound.")
        } catch StoreSignalError.notFound {
            // Expected.
        } catch {
            XCTFail("Expected StoreSignalError.notFound, got \(error).")
        }
    }
    
    func testSend_ThrowsValidationFailedError() async throws {
        let state = RecordingSignalTransportState(
            responseStatus: .unprocessableContent,
            responseBody: #"{"message":"The given data was invalid.","errors":{"type":["The type field is required."]}}"#
        )
        let service = DefaultSignalService(client: makeClient(state: state))
        
        do {
            try await service.send(signal: makeSignal())
            XCTFail("Expected StoreSignalError.validationFailed.")
        } catch StoreSignalError.validationFailed(let message) {
            XCTAssertEqual(message, "The given data was invalid.")
        } catch {
            XCTFail("Expected StoreSignalError.validationFailed, got \(error).")
        }
    }
    
    func testSend_ThrowsUndocumentedError() async throws {
        let state = RecordingSignalTransportState(
            responseStatus: HTTPResponse.Status(code: 418, reasonPhrase: "I'm a teapot"),
            responseBody: #"{"message":"Unexpected signal response."}"#
        )
        let service = DefaultSignalService(client: makeClient(state: state))
        
        do {
            try await service.send(signal: makeSignal())
            XCTFail("Expected StoreSignalError.undocumented.")
        } catch StoreSignalError.undocumented(let statusCode) {
            XCTAssertEqual(statusCode, 418)
        } catch {
            XCTFail("Expected StoreSignalError.undocumented, got \(error).")
        }
    }
    
    private func makeSignal() -> Signal {
        Signal(
            studyIdentifier: "study-123",
            userIdentifier: "study-123-user",
            type: "completedHealthExportUpload",
            payload: [
                "status": "completed"
            ]
        )
    }
    
    private func makeClient(state: RecordingSignalTransportState) -> Client {
        Client(
            baseURL: URL(string: "https://research.example.com")!,
            apiKey: nil,
            transport: RecordingSignalTransport(state: state)
        )
    }
    
}

private struct RecordedSignalRequest: Sendable {
    let request: HTTPRequest
    let body: Data?
    let baseURL: URL
    let operationID: String
}

private actor RecordingSignalTransportState {
    
    var requests: [RecordedSignalRequest] = []
    let responseStatus: HTTPResponse.Status
    let responseBody: String
    
    init(
        responseStatus: HTTPResponse.Status,
        responseBody: String = """
        {
            "signal": {
                "id": 1,
                "participant_identifier": "study-123-user",
                "participant_public_identifier": "participant-123",
                "type": "completedHealthExportUpload",
                "data": {
                    "status": "completed"
                },
                "created_at": "2026-04-27T10:05:00.000000Z"
            }
        }
        """
    ) {
        self.responseStatus = responseStatus
        self.responseBody = responseBody
    }
    
    func record(_ request: RecordedSignalRequest) {
        requests.append(request)
    }
    
}

private struct RecordingSignalTransport: ClientTransport {
    
    let state: RecordingSignalTransportState
    
    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        
        let bodyData: Data?
        if let body {
            bodyData = try await Data(collecting: body, upTo: 1024 * 1024)
        } else {
            bodyData = nil
        }
        
        await state.record(
            RecordedSignalRequest(
                request: request,
                body: bodyData,
                baseURL: baseURL,
                operationID: operationID
            )
        )
        
        let responseStatus = await state.responseStatus
        var response = HTTPResponse(status: responseStatus)
        response.headerFields[.contentType] = "application/json"
        
        let responseBody = await state.responseBody
        return (response, HTTPBody(Data(responseBody.utf8)))
        
    }
    
}
