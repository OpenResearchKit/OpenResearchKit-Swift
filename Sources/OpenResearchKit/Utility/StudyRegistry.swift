//
//  File.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 05.03.26.
//

import Foundation
import SwiftUI
import Combine

public class StudyRegistry: ObservableObject {
    
    public static let shared = StudyRegistry()
    
    // MARK: - Registry -
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    public var studies: [Study] = []
    
    public init(studies: [Study] = []) {
        self.studies = studies
        NotificationCenter.default.publisher(for: .userConsented).sink { [weak self] notification in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }
    
    public func registerStudies(_ studies: [Study]) {
        self.studies = studies
        self.objectWillChange.send()
    }
    
    public var currentActiveStudy: Study? {
        studies
            .first { study in
                return study.isActive
            }
    }
    
}
