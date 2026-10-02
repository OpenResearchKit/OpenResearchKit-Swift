import Foundation
import XCTest

@testable import OpenResearchKit

@MainActor
final class StudyClientFactoryTests: XCTestCase {

    func testFactoryUsesConfigurationAtFirstAccessAndCachesClient() throws {
        var configurations: [UploadConfiguration] = []
        let study = makeStudy { configuration in
            configurations.append(configuration)
            return RecordingStudyAPIClient()
        }
        XCTAssertTrue(configurations.isEmpty)

        let updatedConfiguration = UploadConfiguration(
            serverURL: URL(string: "https://updated.example.org")!,
            uploadFrequency: 7200,
            apiKey: "updated-test-key"
        )
        study.uploadConfiguration = updatedConfiguration

        let uploader = study.uploader
        let client = try XCTUnwrap(study.client as? RecordingStudyAPIClient)
        XCTAssertEqual(configurations.count, 1)
        XCTAssertEqual(configurations.first?.serverURL, updatedConfiguration.serverURL)
        XCTAssertEqual(configurations.first?.apiKey, updatedConfiguration.apiKey)
        XCTAssertEqual(configurations.first?.uploadFrequency, updatedConfiguration.uploadFrequency)

        study.uploadConfiguration = uploadConfiguration
        let fileManager = study.studyFileManager
        XCTAssertTrue(uploader === study.uploader)
        XCTAssertTrue(fileManager === study.studyFileManager)
        XCTAssertTrue(client === (study.client as? RecordingStudyAPIClient))
        XCTAssertEqual(configurations.count, 1)
    }

    func testEveryStudyInitializerForwardsFactoryWithoutCreatingClient() {
        var creationCount = 0
        let mock = RecordingStudyAPIClient()
        let factory: (UploadConfiguration) -> any APIProtocol = { _ in
            creationCount += 1
            return mock
        }
        let surveyURL = URL(string: "https://example.org/survey")!
        let midSurvey = MidStudySurvey(showAfter: 1800, url: surveyURL)
        let studies: [Study] = [
            makeStudy(clientFactory: factory),
            DataDonationStudy(
                studyIdentifier: UUID().uuidString,
                studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                introductorySurveyURL: nil,
                clientFactory: factory
            ),
            LongTermStudy(
                studyIdentifier: UUID().uuidString,
                studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                duration: 3600,
                introductorySurveyURL: nil,
                concludingSurveyURL: nil,
                clientFactory: factory
            ),
            LongTermStudy(
                studyIdentifier: UUID().uuidString,
                studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                studyEndDate: .now.addingTimeInterval(3600),
                introductorySurveyURL: nil,
                concludingSurveyURL: nil,
                clientFactory: factory
            ),
            LongTermWithMidSurveyStudy(
                studyIdentifier: UUID().uuidString,
                studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                duration: 3600,
                introductorySurveyURL: surveyURL,
                midStudySurveys: [midSurvey],
                concludingSurveyURL: surveyURL,
                clientFactory: factory
            ),
            LongTermWithMidSurveyStudy(
                studyIdentifier: UUID().uuidString,
                studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                studyEndDate: .now.addingTimeInterval(3600),
                introductorySurveyURL: surveyURL,
                midStudySurveys: [midSurvey],
                concludingSurveyURL: surveyURL,
                clientFactory: factory
            ),
            LongTermWithMidSurveyStudy(
                studyIdentifier: UUID().uuidString,
                studyInformation: studyInformation,
                uploadConfiguration: uploadConfiguration,
                duration: 3600,
                introductorySurveyURL: surveyURL,
                midStudySurvey: midSurvey,
                concludingSurveyURL: surveyURL,
                clientFactory: factory
            ),
        ]

        XCTAssertEqual(creationCount, 0)
        for (index, study) in studies.enumerated() {
            _ = study.studyFileManager
            XCTAssertTrue(study.client as? RecordingStudyAPIClient === mock)
            XCTAssertEqual(creationCount, index + 1)
        }
        for study in studies {
            _ = study.uploader
            _ = study.client
        }
        XCTAssertEqual(creationCount, studies.count)
    }

    func testPendingUploadsUseFactoryMockAndMarkSuccess() async throws {
        let mock = RecordingStudyAPIClient()
        var creationCount = 0
        let study = makeStudy { _ in
            creationCount += 1
            return mock
        }
        let file = try makeUploadFile(study: study)
        defer { removeStudyData(study: study) }
        XCTAssertEqual(creationCount, 0)

        try await study.uploadRemainingPendingFiles()

        let inputs = await mock.uploadInputs
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(inputs.first?.headers.participantIdentifier, study.userIdentifier)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertNotNil(study.lastSuccessfulUploadDate)
        XCTAssertEqual(creationCount, 1)
    }

    func testUploaderMapsProtocolMockFailureToUploadError() async throws {
        let mock = RecordingStudyAPIClient(
            uploadResponse: .forbidden(.init(body: .json(.init(message: "Test rejection"))))
        )
        let study = makeStudy { _ in mock }
        let file = try makeUploadFile(study: study)
        defer { removeStudyData(study: study) }

        do {
            try await study.uploader.uploadFile(
                filePath: file,
                studyIdentifier: study.studyIdentifier,
                userIdentifier: study.userIdentifier,
                publicUserIdentifier: nil,
                timestamp: "20261002_120000",
                fileName: file.lastPathComponent
            )
            XCTFail("The mock's forbidden response must cause an upload error.")
        } catch {
            guard case UploadError.httpStatus(403) = error else {
                XCTFail("Expected HTTP status 403, received \(error).")
                return
            }
        }
        let inputs = await mock.uploadInputs
        XCTAssertEqual(inputs.count, 1)
    }

    private var studyInformation: StudyInformation {
        StudyInformation(title: "Client Factory Test", subtitle: "", contactEmail: "", image: nil)
    }

    private var uploadConfiguration: UploadConfiguration {
        UploadConfiguration(
            serverURL: URL(string: "https://example.org")!,
            uploadFrequency: 3600,
            apiKey: "test-key"
        )
    }

    private func makeStudy(
        clientFactory: @escaping (UploadConfiguration) -> any APIProtocol
    ) -> Study {
        Study(
            studyIdentifier: "ClientFactoryTest-\(UUID().uuidString)",
            studyInformation: studyInformation,
            uploadConfiguration: uploadConfiguration,
            introductorySurveyURL: nil,
            clientFactory: clientFactory
        )
    }

    private func makeUploadFile(study: Study) throws -> URL {
        let directory = study.studyDirectory(type: .upload)
            .appendingPathComponent("20261002_120000", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("upload.json")
        try Data(#"{"event":"test"}"#.utf8).write(to: file)
        return file
    }

    private func removeStudyData(study: Study) {
        study.store.deleteAllValues()
        try? FileManager.default.removeItem(
            at: study.studyDirectory(type: .upload).deletingLastPathComponent()
        )
    }
}
