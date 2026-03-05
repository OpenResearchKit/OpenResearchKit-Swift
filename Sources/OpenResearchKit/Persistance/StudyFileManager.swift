//
//  StudyFileManager.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import Foundation
import OSLog

public enum FileTransferMode {
    
    /// Moves files in the `working` directory to the upload directory.
    case move
    
    /// Copy files in the `working` directory to the upload directory. Useful for situations where you want to alter the files later and only upload intermediate files.
    case copy
    
}

public enum StudyFileError: Error {
    case notInStudyDirectory
    case notRegularFile
    case wrongSourceDirectory // e.g. trying to transfer from upload -> upload
    case cannotDetermineRelativePath
}

public class StudyFileManager {
    
    public static let shared = StudyFileManager()
    
    public init(studyRegistry: StudyRegistry = StudyRegistry.shared) {
        self.studyRegistry = studyRegistry
    }
    
    private let studyRegistry: StudyRegistry
    private let fileManager: FileManager = .default
    
    /// Deletes all files present in the study directory (either the `upload` or the `working` directory).
    public func deleteAllFiles(study: any UploadsStudyData, type: StudyDataDirectoryType) throws {
        
        Logger.research.info("Removing all files in the directory '\(type.directoryName)' for study \(study.studyIdentifier).")
        
        let baseDirectory = study.studyDirectory(type: type)
        
        for file in try fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil) {
            
            try fileManager.removeItem(at: file)
            
        }
        
        Logger.research.info("Successfully removed all files in the directory '\(type.directoryName)' for study \(study.studyIdentifier).")
        
    }
    
    /// Transfers all regular files from the working directory to the upload directory.
    /// - Parameters:
    ///   - study: The study whose directories to use.
    ///   - mode: Whether to `.move` or `.copy` files. Default: `.move`.
    ///   - overwrite: If `true`, existing files at the destination will be replaced. Default: `true`.
    ///   - includeHiddenFiles: If `false`, dotfiles are skipped. Default: `false`.
    public func transferWorkingToUpload(
        study: Study,
        mode: FileTransferMode = .move,
        overwrite: Bool = true,
        includeHiddenFiles: Bool = false
    ) throws {
        
        let workingDir = study.studyDirectory(type: .working)
        let uploadDir  = study.studyDirectory(type: .upload)
        
        Logger.research.info("Transferring files (\(mode == .move ? "move" : "copy")) from working → upload for study \(study.studyIdentifier).")
        
        let items = try fileManager.contentsOfDirectory(at: workingDir, includingPropertiesForKeys: [.isRegularFileKey], options: [])
        
        for source in items {
            // Skip non-regular files and (optionally) hidden files
            let values = try source.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
            guard values.isRegularFile == true else { continue }
            if !includeHiddenFiles, values.isHidden == true { continue }
            
            let destination = uploadDir.appendingPathComponent(source.lastPathComponent)
            
            do {
                if overwrite, fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                
                switch mode {
                    case .move:
                        try fileManager.moveItem(at: source, to: destination)
                    case .copy:
                        try fileManager.copyItem(at: source, to: destination)
                }
                
            } catch {
                Logger.research.error("Failed to \(mode == .move ? "move" : "copy") \(source.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
        
        Logger.research.info("Transfer complete: succeeded for study \(study.studyIdentifier).")
        
    }
    
    // MARK: - Single-file operations (with strict preconditions)
    
    /// Transfers a **single file** from the study's *working* directory into its *upload* directory.
    /// Preserves subdirectory structure relative to working directory if present.
    public func transferFileToUpload(
        study: Study,
        source: URL,
        mode: FileTransferMode = .move,
        overwrite: Bool = true
    ) throws {
        let workingDir = study.studyDirectory(type: .working)
        let uploadDir  = study.studyDirectory(type: .upload)
        
        // Resolve symlinks/standardization to harden the containment check
        let src = source.resolvingSymlinksInPath().standardizedFileURL
        
        // Precondition 1: must live inside the study's working directory
        guard isDescendant(src, of: workingDir) else {
            throw StudyFileError.wrongSourceDirectory
        }
        // Precondition 2: must be a regular file
        guard try isRegularFile(src) else {
            throw StudyFileError.notRegularFile
        }
        // Compute relative path to preserve subfolders (if any)
        guard let relPath = relativePath(of: src, from: workingDir) else {
            throw StudyFileError.cannotDetermineRelativePath
        }
        let dest = uploadDir.appendingPathComponent(relPath)
        
        // Ensure destination directory exists
        try fileManager.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        if overwrite, fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        switch mode {
            case .move: try fileManager.moveItem(at: src, to: dest)
            case .copy: try fileManager.copyItem(at: src, to: dest)
        }
        Logger.research.info("\(mode == .move ? "Moved" : "Copied") file '\(src.lastPathComponent, privacy: .public)' to upload for study \(study.studyIdentifier).")
    }
    
    /// Deletes a **single file** from either the study's working or upload directory.
    public func deleteFile(study: Study, url: URL) throws {
        
        let workingDir = study.studyDirectory(type: .working)
        let uploadDir = study.studyDirectory(type: .upload)
        
        let target = url.resolvingSymlinksInPath().standardizedFileURL
        
        // Precondition 1: must live inside working or upload dir
        guard isDescendant(target, of: workingDir) || isDescendant(target, of: uploadDir) else {
            throw StudyFileError.notInStudyDirectory
        }
        
        // Precondition 2: must be a regular file (avoid removing directories)
        guard try isRegularFile(target) else {
            throw StudyFileError.notRegularFile
        }
        
        try fileManager.removeItem(at: target)
        
        Logger.research.info("Deleted file '\(target.lastPathComponent, privacy: .public)' for study \(study.studyIdentifier).")
        
    }
    
    // MARK: - Uploading -
    
    public func upload(study: Study, file: URL) async throws {
        
        // Upload the study health data to the one sec study backend
        try await StudyDataUploader.shared.uploadFile(
            filePath: file,
            uploadConfiguration: study.uploadConfiguration,
            studyIdentifier: study.studyIdentifier,
            userIdentifier: study.userIdentifier,
            fileName: file.lastPathComponent
        )
        
        // Delete the file after successful upload (or keep track of successful uploads any other way)
        try self.deleteFile(study: study, url: file)
        
    }
    
    // MARK: - Upload Remaining Files -
    
    public func uploadStudyFolder(study: Study) async throws {
        
        let uploadDirectory = study.studyDirectory(type: .upload)
        
        let items = try FileManager.default.contentsOfDirectory(at: uploadDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [])
        
        for source in items {
            
            // Skip non-regular files and (optionally) hidden files
            let values = try source.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
            guard values.isRegularFile == true else { continue }
            
            if values.isHidden == true { continue }
            
            Logger.research.info("Uploading file '\(source.absoluteString)' of study '\(study.studyIdentifier)'.")
            
            try await upload(study: study, file: source)
            
        }
        
        try await study.didUploadStudyFolder()
        
    }
    
    /// Using this assumes that all data residing in the upload directory was already consented for sharing.
    public func uploadAllRemainingFiles() async throws {
        
        for study in studyRegistry.studies {
            
            // Upload each study folder individually and catch errors here to not block other study uploads.
            do {
                try await self.uploadStudyFolder(study: study)
            } catch {
                Logger.research.error("Failed to upload remaining files of the study \(study.studyIdentifier): \(String(describing: study))")
            }
            
        }
        
    }
    
    public func isUploadFolderEmpty(study: Study) -> Bool {
        
        let uploadDir = study.studyDirectory(type: .upload)
        
        do {
            
            let items = try fileManager.contentsOfDirectory(
                at: uploadDir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
            )
            
            for item in items {
                let values = try item.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
                if values.isRegularFile == true, values.isHidden != true {
                    return false // found a visible, regular file
                }
            }
            
            return true
            
        } catch {
            
            Logger.research.error("Failed to check upload folder for study \(study.studyIdentifier): \(String(describing: error), privacy: .public)")
            
            return false
            
        }
    }
    
    // MARK: - Helpers -
    
    /// True if `child` URL is inside `parent` directory (after resolving symlinks/standardizing).
    private func isDescendant(_ child: URL, of parent: URL) -> Bool {
        let childPath  = child.resolvingSymlinksInPath().standardizedFileURL.path
        let parentPath = parent.resolvingSymlinksInPath().standardizedFileURL.path
        return childPath.hasPrefix(parentPath.hasSuffix("/") ? parentPath : parentPath + "/")
    }
    
    /// Returns the path of `child` relative to `parent` (both resolved). Returns nil if not contained.
    private func relativePath(of child: URL, from parent: URL) -> String? {
        let childURL  = child.resolvingSymlinksInPath().standardizedFileURL
        let parentURL = parent.resolvingSymlinksInPath().standardizedFileURL
        guard isDescendant(childURL, of: parentURL) else { return nil }
        let childPath  = childURL.path
        let parentPath = parentURL.path
        let base = parentPath.hasSuffix("/") ? parentPath : parentPath + "/"
        return String(childPath.dropFirst(base.count))
    }
    
    /// Checks that URL points to a regular file (not dir, not package).
    private func isRegularFile(_ url: URL) throws -> Bool {
        let vals = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
        return vals.isRegularFile == true && vals.isDirectory != true
    }
    
}
