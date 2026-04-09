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
    
    public var studies: [Study] = []
    
    public var currentActiveStudy: Study? {
        studies
            .first { study in
                return study.isActive
            }
    }
    
    public var recommendedStudies: [Study] {
        Study.filterRecommended(studies: studies)
    }
    
    public private(set) var recommendedStudy: Study?
    
    private var randomNumberGenerator: RandomNumberGenerator
    private var cancellables: Set<AnyCancellable> = Set()
    
    public init(studies: [Study] = [], randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.studies = studies
        self.randomNumberGenerator = randomNumberGenerator
        self.reloadRecommendedStudy()
        NotificationCenter.default.publisher(for: .userConsented).sink { [weak self] notification in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Actions -
    
    public func registerStudies(_ studies: [Study]) {
        self.studies.append(contentsOf: studies)
        self.objectWillChange.send()
    }
    
    public func reloadRecommendedStudy() {
        self.recommendedStudy = recommendedStudies.randomElement(using: &randomNumberGenerator)
    }
    
}
