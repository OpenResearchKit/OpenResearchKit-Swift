import Foundation
import OpenResearchKit

actor RecordingServiceAPIClient: MockAPIClient {

    private(set) var enrollmentInputs: [Operations.EnrollParticipant.Input] = []
    private(set) var signalInputs: [Operations.StoreStudySignal.Input] = []
    private(set) var configurationInputs: [Operations.ShowStudyConfiguration.Input] = []
    let enrolledAt = Date(timeIntervalSince1970: 1_777_284_300)
    private let configurationResponse: Operations.ShowStudyConfiguration.Output?

    init(configurationResponse: Operations.ShowStudyConfiguration.Output? = nil) {
        self.configurationResponse = configurationResponse
    }

    func enrollParticipant(_ input: Operations.EnrollParticipant.Input) async throws -> Operations.EnrollParticipant.Output {
        enrollmentInputs.append(input)
        switch input.body {
        case .json(let request):
            return .ok(.init(body: .json(.init(participant: .init(
                participantIdentifier: request.participantIdentifier,
                participantPublicIdentifier: request.participantPublicIdentifier,
                enrolledAt: enrolledAt
            )))))
        }
    }

    func storeStudySignal(_ input: Operations.StoreStudySignal.Input) async throws -> Operations.StoreStudySignal.Output {
        signalInputs.append(input)
        return .created(.init(body: .json(.init(signal: .init(
            id: 1,
            participantIdentifier: input.headers.participantIdentifier,
            participantPublicIdentifier: input.headers.participantPublicIdentifier,
            _type: "test",
            data: .init(),
            createdAt: enrolledAt
        )))))
    }

    func showStudyConfiguration(_ input: Operations.ShowStudyConfiguration.Input) async throws -> Operations.ShowStudyConfiguration.Output {
        configurationInputs.append(input)
        return configurationResponse ?? .ok(.init(body: .json(.init(data: .init(
            studyIdentifier: input.path.studyIdentifier,
            isAvailable: true
        )))))
    }
}
