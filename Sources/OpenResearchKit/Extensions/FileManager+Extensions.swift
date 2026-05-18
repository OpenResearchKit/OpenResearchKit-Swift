//
//  FileManager+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 18.05.26.
//

import Foundation

public extension FileManager {
    
    func isEmptyIgnoringHiddenFiles(directory: URL) -> Bool {
        
        guard let enumerator = self.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return true
        }
        
        for case let fileURL as URL in enumerator {
            
            guard let isRegularFile = try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey]
            ).isRegularFile else {
                continue
            }
            
            if isRegularFile == true {
                return false
            }
            
        }
        
        return true
        
    }
    
}
