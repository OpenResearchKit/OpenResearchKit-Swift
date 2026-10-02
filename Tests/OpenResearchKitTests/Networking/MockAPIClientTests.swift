import OpenResearchKit
import XCTest

@MainActor
final class MockAPIClientTests: XCTestCase {

    func testUnimplementedOperationsThrowThroughAPIProtocol() async {
        let client: any APIProtocol = EmptyMockAPIClient()

        await assertUnimplemented(operationID: Operations.UploadStudyFile.id) {
            try await client.uploadStudyFile(
                headers: .init(participantIdentifier: "participant"),
                body: .multipartForm([])
            )
        }
        await assertUnimplemented(operationID: Operations.EnrollParticipant.id) {
            try await client.enrollParticipant(
                path: .init(studyIdentifier: "study"),
                body: .json(.init(participantIdentifier: "participant"))
            )
        }
        await assertUnimplemented(operationID: Operations.StoreStudySignal.id) {
            try await client.storeStudySignal(
                path: .init(studyIdentifier: "study"),
                headers: .init(participantIdentifier: "participant"),
                body: .json(.genericSignal(.init(_type: "test", data: .init())))
            )
        }
        await assertUnimplemented(operationID: Operations.ShowStudyConfiguration.id) {
            try await client.showStudyConfiguration(path: .init(studyIdentifier: "study"))
        }
        await assertUnimplemented(operationID: Operations.ShowStudyLeaderboard.id) {
            try await client.showStudyLeaderboard(path: .init(studyIdentifier: "study"))
        }
    }

    private func assertUnimplemented<Output: Sendable>(
        operationID: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        call: () async throws -> Output
    ) async {
        do {
            _ = try await call()
            XCTFail("Expected an error for unimplemented operation \(operationID).", file: file, line: line)
        } catch {
            XCTAssertEqual(
                error as? MockAPIClientError,
                .unimplementedOperation(operationID: operationID),
                file: file,
                line: line
            )
        }
    }
}
