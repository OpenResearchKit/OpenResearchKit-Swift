//
//  DefaultSignalService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 29.09.25.
//

import Foundation
import OSLog

enum StoreSignalError: LocalizedError {
    case invalidResponse
    case invalidReturnCode
}

open class DefaultSignalService: SignalService {
    
    private let baseURL: URL
    private let session: URLSession
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func send(signal: Signal) async throws {
        
        let request = try buildStoreSignalRequest(signal)
        let (data, response) = try await session.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            Logger.research.error("Error sending the signal \(String(describing: signal), privacy: .public): Response is not of type HTTPURLResponse.")
            throw StoreSignalError.invalidResponse
        }
        
        guard response.statusCode == 201 else {
            Logger.research.error("Error sending the signal \(String(describing: signal), privacy: .public): Response is not an 201 status code.")
            Logger.research.error("\(String(data: data, encoding: .utf8) ?? "", privacy: .public)")
            throw StoreSignalError.invalidReturnCode
        }
        
        Logger.research.info("Successfully send signal \(String(describing: signal), privacy: .public)")
        
    }
    
    open func buildStoreSignalRequest(_ signal: Signal) throws -> URLRequest {
        
        let url = self.baseURL.appendingPathComponent("api/signals")
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(signal)
        
        return request
        
    }
    
}
