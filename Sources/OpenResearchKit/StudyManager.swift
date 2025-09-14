//
//  StudyManager.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 27.08.25.
//

import SwiftUI

public typealias StudyIdentifier = String

public enum StudyManagerState {
    
    case notActive
    case active(StudyIdentifier)
    
}

public enum EnrollmentError: Error {
    case anotherStudyAlreadyEnrolled
    case notFound
}

public class StudyManager: ObservableObject {
    
    @Published var state: StudyManagerState = .notActive
    
    private let defaults: UserDefaults
    
    public init(
        studies: [StudyDefinition.Type],
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
    }
    
    public var currentState: StudyManagerState {
        return .notActive
    }
    
    public func enrollIfEligible(_ studyId: StudyIdentifier, group: String = "default") throws(EnrollmentError) {
        
        
    }
    
    public func forceEnroll(_ studyId: StudyIdentifier, group: String = "default") throws(EnrollmentError) {
        
    }
    
    public func isActive(_ study: StudyDefinition.Type) -> Bool {
        return true
    }
    
    public var activeStudy: StudyState? {
        return nil
    }
    
}

public protocol StudyState {
    
}

public protocol StudyDefinition {
    
    static var studyId: StudyIdentifier { get }
    
}

public class StanfordStudy: StudyDefinition {
    
    public static var studyId: StudyIdentifier = "stanford-2025"
    
}

public class TikTalkStudy: StudyDefinition {
    
    public static var studyId: StudyIdentifier = "tiktalk-2025"
}

struct MainView: View {
    
    @StateObject var studyManager: StudyManager = .init(studies: [StanfordStudy.self])
    
    var body: some View {
        
        VStack {
            
            switch studyManager.state {
                case .active(let studyIdentifier):
                    Text("")
                    
                case .notActive:
                    Text("No study active")
            }
            
        }
        
    }
    
}
