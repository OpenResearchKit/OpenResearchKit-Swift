import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import OpenResearchKit

@Test("Leaderboard rows decode optional activity timestamps")
func leaderboardRowsDecodeOptionalActivityTimestamps() async throws {
    let client = Client(
        baseURL: URL(string: "https://research.example.com")!,
        apiKey: nil,
        transport: LeaderboardResponseTransport()
    )

    let response = try await client.showStudyLeaderboard(
        path: Operations.ShowStudyLeaderboard.Input.Path(
            studyIdentifier: "bib_irl"
        )
    )
    let rows = try response.ok.body.json.data.rows

    #expect(rows.count == 3)
    let timestampedRow = try #require(rows.first)
    let nullRow = try #require(rows.dropFirst().first)
    let rowWithoutActivity = try #require(rows.dropFirst(2).first)

    #expect(timestampedRow.lastActivityAt == Date(timeIntervalSince1970: 1_777_284_300))
    #expect(nullRow.lastActivityAt == nil)
    #expect(rowWithoutActivity.lastActivityAt == nil)
}

private struct LeaderboardResponseTransport: ClientTransport {
    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var response = HTTPResponse(status: .ok)
        response.headerFields[.contentType] = "application/json"

        let responseBody = """
        {
            "data": {
                "study_identifier": "bib_irl",
                "timezone": "Europe/London",
                "as_of_date": "2026-04-27",
                "rows": [
                    {
                        "rank": 1,
                        "text": "participant-123",
                        "points": 14,
                        "is_current_participant": true,
                        "last_activity_at": "2026-04-27T10:05:00.000000Z"
                    },
                    {
                        "rank": 2,
                        "text": "participant-456",
                        "points": 12,
                        "is_current_participant": false,
                        "last_activity_at": null
                    },
                    {
                        "rank": 3,
                        "text": "participant-789",
                        "points": 10,
                        "is_current_participant": false
                    }
                ]
            }
        }
        """

        return (response, HTTPBody(Data(responseBody.utf8)))
    }
}
