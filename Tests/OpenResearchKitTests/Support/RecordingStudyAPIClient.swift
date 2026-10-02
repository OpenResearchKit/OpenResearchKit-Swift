import OpenResearchKit

actor RecordingStudyAPIClient: MockAPIClient {

    private(set) var uploadInputs: [Operations.UploadStudyFile.Input] = []
    private let uploadResponse: Operations.UploadStudyFile.Output

    init(
        uploadResponse: Operations.UploadStudyFile.Output = .ok(
            .init(body: .json(.init(result: .init(success: true))))
        )
    ) {
        self.uploadResponse = uploadResponse
    }

    func uploadStudyFile(_ input: Operations.UploadStudyFile.Input) async throws -> Operations.UploadStudyFile.Output {
        uploadInputs.append(input)
        return uploadResponse
    }
}
