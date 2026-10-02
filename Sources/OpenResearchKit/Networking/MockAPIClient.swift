/// A partial API mock for application tests and previews.
///
/// Implement the `APIProtocol` operations that the test needs. All other operations
/// throw `MockAPIClientError.unimplementedOperation` without making a network request.
/// Use an actor when the mock records mutable state, because `APIProtocol` requires `Sendable`.
public protocol MockAPIClient: APIProtocol {}

public extension MockAPIClient {

    func uploadStudyFile(_ input: Operations.UploadStudyFile.Input) async throws -> Operations.UploadStudyFile.Output {
        throw MockAPIClientError.unimplementedOperation(operationID: Operations.UploadStudyFile.id)
    }

    func enrollParticipant(_ input: Operations.EnrollParticipant.Input) async throws -> Operations.EnrollParticipant.Output {
        throw MockAPIClientError.unimplementedOperation(operationID: Operations.EnrollParticipant.id)
    }

    func storeStudySignal(_ input: Operations.StoreStudySignal.Input) async throws -> Operations.StoreStudySignal.Output {
        throw MockAPIClientError.unimplementedOperation(operationID: Operations.StoreStudySignal.id)
    }

    func showStudyConfiguration(_ input: Operations.ShowStudyConfiguration.Input) async throws -> Operations.ShowStudyConfiguration.Output {
        throw MockAPIClientError.unimplementedOperation(operationID: Operations.ShowStudyConfiguration.id)
    }

    func showStudyLeaderboard(_ input: Operations.ShowStudyLeaderboard.Input) async throws -> Operations.ShowStudyLeaderboard.Output {
        throw MockAPIClientError.unimplementedOperation(operationID: Operations.ShowStudyLeaderboard.id)
    }
}
