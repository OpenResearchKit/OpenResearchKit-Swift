//
//  StudyUploader.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//

import Foundation
import OSLog
import OpenAPIRuntime
import OpenAPIURLSession

public class StudyDataUploader {

    private let client: Client
    private let clientMetadataProvider: () -> StudyUploadClientMetadata

    internal init(
        client: Client,
        clientMetadataProvider: @escaping () -> StudyUploadClientMetadata = {
            StudyUploadClientMetadata.current()
        }
    ) {
        self.client = client
        self.clientMetadataProvider = clientMetadataProvider
    }
    
    // MARK: - General File Upload -

    internal func uploadFile(
        filePath: URL,
        studyIdentifier: String,
        userIdentifier: String,
        publicUserIdentifier: String?,
        timestamp: String,
        fileName: String
    ) async throws(UploadError) {

        do {

            let fileData = try read(filePath: filePath)
            let multipartBody: MultipartBody<Operations.UploadStudyFile.Input.Body.MultipartFormPayload> = [
                .studyIdentifier(
                    .init(payload: .init(body: HTTPBody(studyIdentifier)))
                ),
                .timestamp(
                    .init(payload: .init(body: HTTPBody(timestamp)))
                ),
                .file(
                    .init(
                        payload: .init(body: HTTPBody(fileData)),
                        filename: fileName
                    )
                ),
            ]

            let clientMetadata = clientMetadataProvider()
            let response = try await client.uploadStudyFile(
                headers: .init(
                    participantIdentifier: userIdentifier,
                    participantPublicIdentifier: publicUserIdentifier,
                    clientVersion: clientMetadata.clientVersion,
                    clientBuild: clientMetadata.clientBuild,
                    clientPlatform: clientMetadata.clientPlatform,
                    clientOSVersion: clientMetadata.clientOSVersion,
                    clientDeviceModel: clientMetadata.clientDeviceModel,
                    clientTimezone: clientMetadata.clientTimezone,
                    clientLocale: clientMetadata.clientLocale,
                    clientLocales: clientMetadata.clientLocales
                ),
                body: .multipartForm(multipartBody)
            )

            switch response {
                case .ok:
                    Logger.research.info("Uploaded file \(fileName) for user \(userIdentifier) successfully")
                case .forbidden:
                    throw UploadError.httpStatus(403)
                case .notFound:
                    throw UploadError.httpStatus(404)
                case .unprocessableContent:
                    throw UploadError.httpStatus(422)
                case .undocumented(let statusCode, _):
                    throw UploadError.httpStatus(statusCode)
            }

        } catch let error as UploadError {
            throw error
        } catch {
            throw UploadError.networkingError(error)
        }

    }

    private func read(filePath: URL) throws (UploadError) -> Data {

        do {
            return try Data(contentsOf: filePath)
        } catch {
            throw UploadError.fileReadFailed(error)
        }

    }

}
