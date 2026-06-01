//
//  DefaultSignalService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 29.09.25.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import OSLog

public enum StoreSignalError: LocalizedError {
    case invalidResponse
    case notFound
    case validationFailed(message: String)
    case undocumented(statusCode: Int)
    case unexpected(message: String)
    
    public var errorDescription: String? {
        switch self {
            case .invalidResponse:
                return "The signal response was invalid."
            case .notFound:
                return "The study could not be found."
            case .validationFailed(let message):
                return "The signal endpoint rejected the signal: \(message)"
            case .undocumented(let statusCode):
                return "The signal endpoint returned an undocumented status code: \(statusCode)"
            case .unexpected(let message):
                return "The signal request failed unexpectedly: \(message)"
        }
    }
}

open class DefaultSignalService: SignalService {
    
    private let client: Client
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.client = Client(
            serverURL: baseURL,
            configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
            transport: URLSessionTransport(
                configuration: URLSessionTransport.Configuration(session: session)
            ),
            middlewares: [
                AcceptLanguageMiddleware(),
                GeneratedHeaderParameterDecodingMiddleware(),
            ]
        )
    }
    
    public init(client: Client) {
        self.client = client
    }
    
    public func send(signal: Signal) async throws {
        
        do {
            let response = try await client.storeStudySignal(
                path: Operations.StoreStudySignal.Input.Path(
                    studyIdentifier: signal.studyIdentifier
                ),
                headers: Operations.StoreStudySignal.Input.Headers(
                    participantIdentifier: signal.userIdentifier,
                    participantPublicIdentifier: signal.publicUserIdentifier,
                    accept: .defaultValues()
                ),
                body: Operations.StoreStudySignal.Input.Body.json(
                    try buildStoreSignalRequest(signal)
                )
            )
            
            switch response {
                case .created:
                    Logger.research.info("Successfully send signal \(String(describing: signal), privacy: .public)")
                case .notFound:
                    Logger.research.error("Error sending the signal \(String(describing: signal), privacy: .public): Study not found.")
                    throw StoreSignalError.notFound
                case .unprocessableContent(let data):
                    let error = try data.body.json
                    Logger.research.error("Error sending the signal \(String(describing: signal), privacy: .public): \(error.message, privacy: .public)")
                    throw StoreSignalError.validationFailed(message: error.message)
                case .undocumented(let statusCode, _):
                    Logger.research.error("Error sending the signal \(String(describing: signal), privacy: .public): Undocumented response \(statusCode).")
                    throw StoreSignalError.undocumented(statusCode: statusCode)
            }
        } catch let error as StoreSignalError {
            throw error
        } catch {
            Logger.research.error("Error sending the signal \(String(describing: signal), privacy: .public): \(String(describing: error), privacy: .public)")
            throw StoreSignalError.unexpected(message: String(describing: error))
        }
        
    }
    
    open func buildStoreSignalRequest(_ signal: Signal) throws -> Components.Schemas.StoreSignalRequest {
        let data = try Components.Schemas.GenericSignal.DataPayload(
            additionalProperties: OpenAPIObjectContainer(
                unvalidatedValue: signal.payload
            )
        )
        let signal = Components.Schemas.GenericSignal(
            _type: signal.type,
            data: data
        )
        
        return Components.Schemas.StoreSignalRequest.genericSignal(signal)
    }
    
}
