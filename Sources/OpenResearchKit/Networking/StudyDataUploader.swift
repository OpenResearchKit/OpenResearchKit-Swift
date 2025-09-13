//
//  StudyUploader.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//

import Foundation
import OSLog

public enum UploadError: Error {
    
    case fileReadFailed(Error)
    case networkingError(Error)
    
    case alreadyUploading
    
    case invalidResponse
    case httpStatus(Int)
    case serverRejected(String?)
}

public class StudyDataUploader {
    
    public static let shared = StudyDataUploader()
    
    private let session = URLSession.shared
    
    private var isCurrentlyUploading = false
    
    @available(*, deprecated, message: "Use the general uploading method `uploadFile(...)` in the future.")
    public func uploadJSON(
        filePath: URL,
        uploadConfiguration: UploadConfiguration,
        userIdentifier: String,
        fileName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        if isCurrentlyUploading {
            return
        }
        
        isCurrentlyUploading = true
        
        if let data = try? Data(contentsOf: filePath) {
            
            let uploadSession = MultipartFormDataRequest.withConfiguration(
                uploadConfiguration: uploadConfiguration,
                userIdentifier: userIdentifier
            )
            uploadSession.addDataField(
                named: "file",
                filename: fileName,
                data: data,
                mimeType: "application/octet-stream"
            )
            
            
            let task = session.dataTask(with: uploadSession) { data, response, error in
                
                self.isCurrentlyUploading = false
                
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let result = json["result"] as? [String: Any], let hadSuccess = result["success"] as? String {
                        
                        print(hadSuccess)
                        print(json)
                        
                        if hadSuccess == "true" {
                            completion(.success(()))
                        }
                    }
                }
            }
            
            task.resume()
            
        } else {
            self.isCurrentlyUploading = false
        }
    }
    
    // MARK: - General File Upload -
    
    public func uploadFile(
        filePath: URL,
        uploadConfiguration: UploadConfiguration,
        userIdentifier: String,
        fileName: String
    ) async throws(UploadError) {
        
        let fileData = try read(filePath: filePath)
        let uploadSession = MultipartFormDataRequest.withConfiguration(
            uploadConfiguration: uploadConfiguration,
            userIdentifier: userIdentifier
        )
        
        uploadSession.addDataField(
            named: "file",
            filename: fileName,
            data: fileData,
            mimeType: "application/octet-stream"
        )
        
        do {
            
            let (data, response) = try await session.data(with: uploadSession)
            
            guard let response = response as? HTTPURLResponse else {
                throw UploadError.invalidResponse
            }
            
            if response.statusCode != 200 {
                throw UploadError.httpStatus(response.statusCode)
            }
            
            let uploadResponse = try JSONDecoder().decode(StudyDataUploadResponse.self, from: data)
            
            if !uploadResponse.results.success {
                throw UploadError.serverRejected("Upload not successful")
            }
            
            Logger.research.info("Uploaded file \(fileName) for user \(userIdentifier) successfully")
            
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
