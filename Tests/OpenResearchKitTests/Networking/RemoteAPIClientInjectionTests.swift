import Foundation
import OpenResearchKit
import XCTest

@MainActor
final class RemoteAPIClientInjectionTests: XCTestCase {

    func testEnrollmentAcceptsAPIMockAndStoresEnrollmentDate() async throws {
        let mock = RecordingServiceAPIClient()
        let service = RemoteEnrollmentService(client: mock)
        let study = makeStudy()
        defer { try? study.reset() }

        try await service.enroll(study: study)

        let inputs = await mock.enrollmentInputs
        let input = try XCTUnwrap(inputs.first)
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(input.path.studyIdentifier, study.studyIdentifier)
        switch input.body {
        case .json(let request):
            XCTAssertEqual(request.participantIdentifier, study.userIdentifier)
            XCTAssertEqual(request.participantPublicIdentifier, study.publicUserIdentifier)
        }
        XCTAssertEqual(study.enrolledRemoteAt, mock.enrolledAt)
    }

    func testSignalsAcceptAPIMockAndForwardParticipantIdentifiers() async throws {
        let mock = RecordingServiceAPIClient()
        let service = DefaultSignalService(client: mock)

        try await service.send(signal: Signal(
            studyIdentifier: "study",
            userIdentifier: "participant",
            publicUserIdentifier: "public-participant",
            type: "test"
        ))

        let inputs = await mock.signalInputs
        let input = try XCTUnwrap(inputs.first)
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(input.path.studyIdentifier, "study")
        XCTAssertEqual(input.headers.participantIdentifier, "participant")
        XCTAssertEqual(input.headers.participantPublicIdentifier, "public-participant")
    }

    func testConfigurationAcceptsAPIMock() async throws {
        let mock = RecordingServiceAPIClient()
        let service = RemoteStudyConfigurationService(client: mock)
        let study = makeStudy()

        let isAvailable = try await service.isAvailable(for: study)

        XCTAssertEqual(isAvailable, true)
        let inputs = await mock.configurationInputs
        XCTAssertEqual(inputs.map(\.path.studyIdentifier), [study.studyIdentifier])
    }

    func testMissingConfigurationFromAPIMockReturnsNil() async throws {
        let mock = RecordingServiceAPIClient(
            configurationResponse: .notFound(.init(body: .json(.init(message: "Missing study"))))
        )
        let service = RemoteStudyConfigurationService(client: mock)

        let isAvailable = try await service.isAvailable(for: makeStudy())

        XCTAssertNil(isAvailable)
    }

    func testUnexpectedConfigurationResponseFromAPIMockThrows() async {
        let mock = RecordingServiceAPIClient(
            configurationResponse: .undocumented(statusCode: 503, .init())
        )
        let service = RemoteStudyConfigurationService(client: mock)

        do {
            _ = try await service.isAvailable(for: makeStudy())
            XCTFail("Expected an error for an unexpected configuration response.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }

    func testConfigurationFactoryIsDeferredAndUsesCurrentConfigurationForEachCheck() async throws {
        let mock = RecordingServiceAPIClient()
        var configurations: [UploadConfiguration] = []
        let service = RemoteStudyConfigurationService { configuration in
            configurations.append(configuration)
            return mock
        }
        XCTAssertTrue(configurations.isEmpty)
        let firstStudy = makeStudy()
        let secondStudy = makeStudy()
        firstStudy.uploadConfiguration = configuration(server: "updated", apiKey: "updated-test-key")

        _ = try await service.isAvailable(for: firstStudy)
        firstStudy.uploadConfiguration = configuration(server: "later", apiKey: "later-test-key")
        _ = try await service.isAvailable(for: firstStudy)
        _ = try await service.isAvailable(for: secondStudy)

        XCTAssertEqual(configurations.map(\.serverURL), [
            URL(string: "https://updated.example.org")!,
            URL(string: "https://later.example.org")!,
            secondStudy.uploadConfiguration.serverURL,
        ])
        XCTAssertEqual(configurations.map(\.apiKey), [
            "updated-test-key", "later-test-key", secondStudy.uploadConfiguration.apiKey,
        ])
        let inputs = await mock.configurationInputs
        XCTAssertEqual(inputs.map(\.path.studyIdentifier), [
            firstStudy.studyIdentifier, firstStudy.studyIdentifier, secondStudy.studyIdentifier,
        ])
    }

    func testRegistryUsesConfigurationAPIMockForRecommendations() async {
        let study = makeStudy()
        let mock = RecordingServiceAPIClient(configurationResponse: .ok(.init(body: .json(.init(
            data: .init(studyIdentifier: study.studyIdentifier, isAvailable: false)
        )))))
        let registry = StudyRegistry(
            studies: [study],
            studyConfigurationService: RemoteStudyConfigurationService(client: mock)
        )

        await registry.refreshRecommendations()

        let inputs = await mock.configurationInputs
        XCTAssertEqual(inputs.map(\.path.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudies.isEmpty)
    }

    private func makeStudy() -> Study {
        DataDonationStudy(
            studyIdentifier: "RemoteAPIClientTest-\(UUID().uuidString)",
            studyInformation: .init(title: "API Client Test", subtitle: "", contactEmail: "", image: nil),
            uploadConfiguration: configuration(server: "original", apiKey: "test-key"),
            introductorySurveyURL: URL(string: "https://example.org/survey"),
            clientFactory: { _ in EmptyMockAPIClient() }
        )
    }

    private func configuration(server: String, apiKey: String) -> UploadConfiguration {
        UploadConfiguration(
            serverURL: URL(string: "https://\(server).example.org")!,
            uploadFrequency: 3600,
            apiKey: apiKey
        )
    }
}
