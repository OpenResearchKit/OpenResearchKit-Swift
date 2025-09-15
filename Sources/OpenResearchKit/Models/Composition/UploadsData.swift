//
//  UploadsData.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import Foundation
import OSLog

public protocol UploadsStudyData: GeneralStudy {
    
    var uploadConfiguration: UploadConfiguration { get }
    
    func uploadIfNecessary()
    
    func shouldUpload() -> Bool
    
    func appendNewJSONObjects(newObjects: [[String: JSONConvertible]])
    
}

extension UploadsStudyData {
    
    // MARK: - Files and Data
    
    public func studyDirectory(type: StudyDataDirectoryType = .working) -> URL {
        
        let fileManager = FileManager.default
        let studyDirectoryURL = baseDirectory
            .appendingPathComponent("OpenResearchKit/Studies", isDirectory: true)
            .appendingPathComponent(studyIdentifier, isDirectory: true)
            .appendingPathComponent(type.directoryName, isDirectory: true)
        
        // Ensure the directory exists
        do {
            try fileManager.createDirectory(
                at: studyDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            Logger.research.error("Failed to create study directory: \(error)")
        }
        
        return studyDirectoryURL
        
    }
    
    public func appendNewJSONObjects(newObjects: [[String: JSONConvertible]]) {
        
        if hasUserGivenConsent {
            // only add data if study is running: user has given consent and study has not yet ended
            var existingFile = self.JSONFile
            existingFile.append(contentsOf: newObjects)
            self.saveAndUploadIfNeccessary(jsonFile: existingFile)
        }
        
    }
    
    private func saveAndUploadIfNeccessary(jsonFile: [ [String: Any] ]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonFile, options: .prettyPrinted) {
            try? jsonData.write(to: jsonDataFilePath)
            self.uploadIfNecessary()
        }
    }
    
    internal var JSONFile: [[String: Any]] {
        if let jsonData = try? Data(contentsOf: jsonDataFilePath),
           let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let json = decoded as? [ [String: Any] ] {
            return json
        }
        
        return []
    }
    
    private var mainFileName: String {
        "study-\(studyIdentifier)-\(userIdentifier).json"
    }
    
    private var jsonDataFilePath: URL {
        return baseDirectory.appendingPathComponent(mainFileName)
    }
    
    private var baseDirectory: URL {
        
        if let sharedAppGroupIdentifier {
            let fileManager = FileManager.default
            return fileManager.containerURL(forSecurityApplicationGroupIdentifier: sharedAppGroupIdentifier)!
        }
        
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    }
    
    // MARK: - Upload
    
    public func shouldUpload() -> Bool {
        
        guard let lastSuccessfulUploadDate else {
            return true
        }
        
        if abs(lastSuccessfulUploadDate.timeIntervalSinceNow) > uploadConfiguration.uploadFrequency {
            return true
        }
        
        return false
        
    }
    
    public func uploadIfNecessary() {
        
        if shouldUpload() {
            self.uploadJSON()
        }
        
    }
    
    public var lastSuccessfulUploadDate: Date? {
        return store.get(Study.Keys.LastSuccessfulUploadDate, type: Date.self)
    }
    
    internal func uploadJSON() {
        
        StudyDataUploader.shared.uploadJSON(
            filePath: jsonDataFilePath,
            uploadConfiguration: uploadConfiguration,
            userIdentifier: userIdentifier,
            fileName: mainFileName
        ) { (result: Result<Void, any Error>) in
            
            switch result {
                    
                case .success(_):
                    DispatchQueue.main.async {
                        self.updateUploadDate()
                    }
                    
                case .failure(let error):
                    print(error)
                    
            }
            
        }
        
    }
    
    private func updateUploadDate(newDate: Date = Date()) {
        
        store.update(Study.Keys.LastSuccessfulUploadDate, value: newDate)
        publishChangesOnMain()
        
    }
    
}
