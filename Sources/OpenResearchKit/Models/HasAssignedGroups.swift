//
//  HasAssignedGroups.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

public protocol HasAssignedGroups: AnyObject, GeneralStudy {
    
    var assignedGroup: String? { get set }
    
}

extension HasAssignedGroups {
    
    public var assignedGroup: String? {
        get {
            return store.get(Study.Keys.AssignedGroup, type: String.self)
        }
        
        set {
            store.update(Study.Keys.AssignedGroup, value: newValue)
            publishChangesOnMain()
        }
    }
    
}
