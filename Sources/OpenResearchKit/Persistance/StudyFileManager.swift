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
    case cannotDetermineUploadTimestamp
    case duplicateUploadFileNames(timestamp: String, fileNames: [String])
    case flatUploadFileFound(URL)
    case invalidUploadBatchDirectory(URL)
}

public class StudyFileManager {

    public init(
        studiesProvider: @escaping @MainActor @Sendable () -> [Study] = {
            StudyRegistry.shared.studies
        },
        uploader: StudyDataUploader
    ) {
        self.studiesProvider = studiesProvider
        self.uploader = uploader
    }

    private let studiesProvider: @MainActor @Sendable () -> [Study]
    private let fileManager: FileManager = .default
    private let uploader: StudyDataUploader

    internal static func uploadTimestampString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }

    public func uploadBatchDirectory(study: Study, date: Date? = nil) throws -> URL {
        let timestamp = Self.uploadTimestampString(from: date ?? study.dateGenerator.generate())
        let directory = study.studyDirectory(type: .upload)
            .appendingPathComponent(timestamp, isDirectory: true)

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory
    }

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
        let uploadDir = try uploadBatchDirectory(study: study)

        Logger.research.info("Transferring files (\(mode == .move ? "move" : "copy")) from working → upload batch \(uploadDir.lastPathComponent, privacy: .public) for study \(study.studyIdentifier, privacy: .public).")

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
        let uploadDir  = try uploadBatchDirectory(study: study)

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
        let timestamp = try uploadTimestamp(for: file, study: study)
        try await upload(study: study, file: file, timestamp: timestamp)
    }

    private func upload(study: Study, file: URL, timestamp: String) async throws {

        // Upload the study data to the configured study backend.
        try await uploader.uploadFile(
            filePath: file,
            studyIdentifier: study.studyIdentifier,
            userIdentifier: study.userIdentifier,
            publicUserIdentifier: study.publicUserIdentifier,
            timestamp: timestamp,
            fileName: file.lastPathComponent
        )
        
        // Delete the file after successful upload (or keep track of successful uploads any other way)
        try self.deleteFile(study: study, url: file)
        
    }
    
    // MARK: - Upload Remaining Files -
    
    public func uploadStudyFolder(study: Study) async throws {
        
        let uploadDirectory = study.studyDirectory(type: .upload)
        let batchDirectories = try uploadBatchDirectories(in: uploadDirectory)
        var didUploadFile = false

        for batchDirectory in batchDirectories {
            let timestamp = batchDirectory.lastPathComponent
            let files = try uploadableFiles(in: batchDirectory)

            try validateUniqueUploadFileNames(files: files, timestamp: timestamp)

            for source in files {
                Logger.research.info("Uploading file '\(source.absoluteString)' of study '\(study.studyIdentifier)' from batch '\(timestamp, privacy: .public)'.")

                try await upload(study: study, file: source, timestamp: timestamp)
                didUploadFile = true
            }

            try removeEmptyDirectories(under: batchDirectory)

        }

        if didUploadFile {
            study.markUploadSuccessful()
            try await study.didUploadStudyFolder()
        }

    }
    
    /// Using this assumes that all data residing in the upload directory was already consented for sharing.
    public func uploadAllRemainingFiles() async throws {
        
        for study in await studiesProvider() {
            
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

            return try uploadableFiles(in: uploadDir).isEmpty

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

    private func isDirectory(_ url: URL) throws -> Bool {
        let vals = try url.resourceValues(forKeys: [.isDirectoryKey])
        return vals.isDirectory == true
    }

    private func uploadTimestamp(for file: URL, study: Study) throws -> String {
        let uploadDirectory = study.studyDirectory(type: .upload)

        guard let relativePath = relativePath(of: file, from: uploadDirectory) else {
            throw StudyFileError.notInStudyDirectory
        }

        guard let timestamp = relativePath.split(separator: "/").first.map(String.init) else {
            throw StudyFileError.cannotDetermineUploadTimestamp
        }

        guard isCanonicalUploadTimestamp(timestamp) else {
            throw StudyFileError.invalidUploadBatchDirectory(file.deletingLastPathComponent())
        }

        return timestamp
    }

    private func uploadBatchDirectories(in uploadDirectory: URL) throws -> [URL] {
        let items = try fileManager.contentsOfDirectory(
            at: uploadDirectory,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isHiddenKey],
            options: []
        )

        var directories: [URL] = []

        for item in items {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isHiddenKey])

            if values.isHidden == true {
                continue
            }

            if values.isRegularFile == true {
                throw StudyFileError.flatUploadFileFound(item)
            }

            guard values.isDirectory == true else {
                continue
            }

            guard isCanonicalUploadTimestamp(item.lastPathComponent) else {
                throw StudyFileError.invalidUploadBatchDirectory(item)
            }

            directories.append(item)
        }

        return directories.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func uploadableFiles(in directory: URL) throws -> [URL] {
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        if try isRegularFile(directory) {
            return [directory]
        }

        guard try isDirectory(directory) else {
            return []
        }

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []

        for case let url as URL in enumerator {
            if try isRegularFile(url) {
                files.append(url)
            }
        }

        return files.sorted { $0.path < $1.path }
    }

    private func validateUniqueUploadFileNames(files: [URL], timestamp: String) throws {
        let grouped = Dictionary(grouping: files, by: \.lastPathComponent)
        let duplicates = grouped
            .filter { $0.value.count > 1 }
            .map(\.key)
            .sorted()

        if !duplicates.isEmpty {
            throw StudyFileError.duplicateUploadFileNames(timestamp: timestamp, fileNames: duplicates)
        }
    }

    private func isCanonicalUploadTimestamp(_ timestamp: String) -> Bool {
        let pattern = #"^\d{8}_\d{6}$"#
        return timestamp.range(of: pattern, options: .regularExpression) != nil
    }

    private func removeEmptyDirectories(under directory: URL) throws {
        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let directories = enumerator
            .compactMap { $0 as? URL }
            .filter { (try? isDirectory($0)) == true }
            .sorted { $0.path.count > $1.path.count }

        for childDirectory in directories {
            if try isDirectoryEmpty(childDirectory) {
                try fileManager.removeItem(at: childDirectory)
            }
        }

        if try isDirectoryEmpty(directory) {
            try fileManager.removeItem(at: directory)
        }
    }

    private func isDirectoryEmpty(_ directory: URL) throws -> Bool {
        try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: []).isEmpty
    }

}
