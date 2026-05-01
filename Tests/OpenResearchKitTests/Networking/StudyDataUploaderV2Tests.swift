//
//  StudyDataUploaderV2Tests.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 30.04.26.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import XCTest

@testable import OpenResearchKit

final class StudyDataUploaderV2Tests: XCTestCase {

    func testUploadFile_UsesGeneratedV2RequestWithHeadersAndTimestamp() async throws {
        let state = RecordingTransportState()
        let uploader = StudyDataUploader(client: makeClient(state: state))
        let file = try makeTemporaryFile(name: "upload.json", contents: #"{"ok":true}"#)

        try await uploader.uploadFile(
            filePath: file,
            studyIdentifier: "study-123",
            userIdentifier: "study-123-user",
            publicUserIdentifier: "participant-123",
            timestamp: "20260428_120000",
            fileName: "upload.json"
        )

        let requests = await state.requests
        let recordedRequest = try XCTUnwrap(requests.first)
        let body = try XCTUnwrap(recordedRequest.body)
        let bodyString = String(data: body, encoding: .utf8) ?? ""

        XCTAssertEqual(recordedRequest.operationID, "uploadStudyFile")
        XCTAssertEqual(recordedRequest.baseURL, URL(string: "https://research.example.com")!)
        XCTAssertEqual(recordedRequest.request.headerFields[HTTPField.Name("X-API-Key")!], "secret-key")
        XCTAssertEqual(recordedRequest.request.headerFields[HTTPField.Name("Participant-Identifier")!], "study-123-user")
        XCTAssertEqual(recordedRequest.request.headerFields[HTTPField.Name("Participant-Public-Identifier")!], "participant-123")
        XCTAssertTrue(bodyString.contains("name=\"study_identifier\""))
        XCTAssertTrue(bodyString.contains("study-123"))
        XCTAssertTrue(bodyString.contains("name=\"timestamp\""))
        XCTAssertTrue(bodyString.contains("20260428_120000"))
        XCTAssertTrue(bodyString.contains("filename=\"upload.json\""))
        XCTAssertTrue(bodyString.contains(#"{"ok":true}"#))
    }

    func testUploadStudyFolder_DeletesSuccessfulFilesAndMarksUpload() async throws {
        let state = RecordingTransportState()
        let uploader = StudyDataUploader(client: makeClient(state: state))
        let manager = StudyFileManager(uploader: uploader)
        let study = UploadTestStudy.makeStudy(id: "SuccessfulUploadStudy-\(UUID().uuidString)")
        let file = try createUploadFile(study: study, timestamp: "20260428_120000", name: "upload.json")

        try await manager.uploadStudyFolder(study: study)

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
        XCTAssertNotNil(study.lastSuccessfulUploadDate)
        let requestCount = await state.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testUploadStudyFolder_KeepsFailedFilesForRetry() async throws {
        let state = RecordingTransportState(shouldFail: true)
        let uploader = StudyDataUploader(client: makeClient(state: state))
        let manager = StudyFileManager(uploader: uploader)
        let study = UploadTestStudy.makeStudy(id: "FailedUploadStudy-\(UUID().uuidString)")
        let file = try createUploadFile(study: study, timestamp: "20260428_120000", name: "upload.json")

        do {
            try await manager.uploadStudyFolder(study: study)
            XCTFail("Expected upload failure.")
        } catch {
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
            XCTAssertNil(study.lastSuccessfulUploadDate)
        }
    }

    private func makeTemporaryFile(name: String, contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent(name)
        try Data(contents.utf8).write(to: file)
        return file
    }

    private func makeClient(state: RecordingTransportState) -> Client {
        Client(
            baseURL: URL(string: "https://research.example.com")!,
            apiKey: "secret-key",
            transport: RecordingTransport(state: state)
        )
    }

    private func createUploadFile(study: Study, timestamp: String, name: String) throws -> URL {
        let file = study.studyDirectory(type: .upload)
            .appendingPathComponent(timestamp, isDirectory: true)
            .appendingPathComponent(name)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"ok":true}"#.utf8).write(to: file)
        return file
    }

}

private struct RecordedRequest: Sendable {
    let request: HTTPRequest
    let body: Data?
    let baseURL: URL
    let operationID: String
}

private actor RecordingTransportState {

    var requests: [RecordedRequest] = []
    let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func record(_ request: RecordedRequest) {
        requests.append(request)
    }

    func requestCount() -> Int {
        requests.count
    }

}

private struct RecordingTransport: ClientTransport {

    let state: RecordingTransportState

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
            RecordedRequest(
                request: request,
                body: bodyData,
                baseURL: baseURL,
                operationID: operationID
            )
        )

        if state.shouldFail {
            throw URLError(.notConnectedToInternet)
        }

        var response = HTTPResponse(status: .ok)
        response.headerFields[.contentType] = "application/json"
        let responseBody = #"{"result":{"success":true,"path":"uploads/study/upload.json"}}"#

        return (response, HTTPBody(Data(responseBody.utf8)))

    }

}

private final class UploadTestStudy: DataDonationStudy {

    static func makeStudy(id: String) -> UploadTestStudy {
        UploadTestStudy(
            studyIdentifier: id,
            studyInformation: StudyInformation(
                title: "Upload Test",
                subtitle: "Upload Test",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                serverURL: URL("https://example.org")!,
                uploadFrequency: 3600,
                apiKey: ""
            ),
            introductorySurveyURL: nil,
            participationIsPossible: true
        )
    }

}
