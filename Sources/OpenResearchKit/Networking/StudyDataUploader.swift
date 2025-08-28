//
//  StudyUploader.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//

import Foundation

public class StudyDataUploader {
    
    public static let shared = StudyDataUploader()
    
    private var isCurrentlyUploading = false
    
    public func uploadJSON(
        filePath: URL,
        fileSubmissionServer: URL,
        apiKey: String,
        userIdentifier: String,
        fileName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        
        if isCurrentlyUploading {
            return
        }
        
        isCurrentlyUploading = true
        
        if let data = try? Data(contentsOf: filePath) {
            
            let uploadSession = MultipartFormDataRequest(url: fileSubmissionServer)
            uploadSession.addTextField(named: "api_key", value: apiKey)
            uploadSession.addTextField(named: "user_key", value: userIdentifier)
            uploadSession.addDataField(
                named: "file",
                filename: fileName,
                data: data,
                mimeType: "application/octet-stream"
            )
            
            
            let task = URLSession.shared.dataTask(with: uploadSession) { data, response, error in
                
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
    
}
