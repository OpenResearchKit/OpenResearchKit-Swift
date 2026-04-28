//
//  Study+RemoteEnrollment.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.04.26.
//

import Foundation

public extension Study {
    
    internal(set) var enrolledRemoteAt: Date? {
        
        get {
            return store.get(Study.Keys.EnrolledRemoteAt, type: Date.self)
        }
        set {
            store.update(Study.Keys.EnrolledRemoteAt, value: newValue)
            publishChangesOnMain()
        }
        
    }
    
}

extension Study.Keys {
    
    static let EnrolledRemoteAt = "enrolledRemoteAt"
    
}
