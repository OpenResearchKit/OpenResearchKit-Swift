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
    
    private let session: URLSession
    
    private init() {
        
        let appBundleName = Bundle.main.bundleURL.lastPathComponent.lowercased().replacingOccurrences(of: " ", with: ".")
        let sessionIdentifier: String = "wtf.riedel.one-sec.\(appBundleName)"
        let configuration = URLSessionConfiguration.background(withIdentifier: appBundleName)
        
        #if DEBUG
        // For testing: Set isDiscretionary to false during development to avoid long delays and ensure tasks are executed immediately.
        configuration.isDiscretionary = false
        #endif
        
        // Ensure the app is launched or resumed in the background when a download or upload task completes.
        configuration.sessionSendsLaunchEvents = true
        
        self.session = URLSession.shared
        
    }
    
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
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                        let result = json["result"] as? [String: Any] {
                        
                        // Needed because of legacy API implementation
                        let stringCast = result["success"] as? String
                        let boolCast = result["success"] as? Bool
                        
                        if stringCast != nil || boolCast != nil {
                            
                            print(result["success"] ?? "")
                            print(json)
                            
                            if stringCast == "true" || boolCast == true {
                                completion(.success(()))
                            }
                            
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
        studyIdentifier: String,
        userIdentifier: String,
        fileName: String
    ) async throws(UploadError) {
        
        let fileData = try read(filePath: filePath)
        let uploadSession = MultipartFormDataRequest.withConfiguration(
            uploadConfiguration: uploadConfiguration,
            userIdentifier: userIdentifier
        )
        
        uploadSession.addTextField(named: "study_identifier", value: studyIdentifier)
        
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
            
            if !uploadResponse.result.success {
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
