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
    
    public private(set) var studies: [Study] = [] {
        didSet {
            syncStudyObservers()
            refreshDerivedState()
        }
    }
    
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
    
    private var randomNumberGenerator: any RandomNumberGenerator
    private var studyObserverCancellables: [ObjectIdentifier: AnyCancellable] = [:]
    
    public init(
        studies: [Study] = [],
        randomNumberGenerator: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.studies = studies
        self.randomNumberGenerator = randomNumberGenerator
        self.syncStudyObservers()
        self.refreshDerivedState()
    }
    
    // MARK: - Actions -
    
    public func registerStudies(_ studies: [Study]) {
        self.studies.append(contentsOf: studies)
    }
    
    public func reloadRecommendedStudy() {
        self.recommendedStudy = recommendedStudies.randomStudy(using: &randomNumberGenerator)
    }
    
    // MARK: - Helpers -
    
    private func syncStudyObservers() {
        let currentStudyIdentifiers = Set(studies.map { ObjectIdentifier($0) })
        let staleIdentifiers = studyObserverCancellables.keys.filter { !currentStudyIdentifiers.contains($0) }
        
        for identifier in staleIdentifiers {
            studyObserverCancellables[identifier]?.cancel()
            studyObserverCancellables.removeValue(forKey: identifier)
        }
        
        for study in studies {
            let identifier = ObjectIdentifier(study)
            
            guard studyObserverCancellables[identifier] == nil else {
                continue
            }
            
            studyObserverCancellables[identifier] = study.objectWillChange
                .sink { [weak self] _ in
                    self?.refreshDerivedState()
                }
        }
    }
    
    private func refreshDerivedState() {
        let availableRecommendedStudies = recommendedStudies
        
        if let recommendedStudy,
           availableRecommendedStudies.contains(where: { $0 === recommendedStudy }) {
            self.recommendedStudy = recommendedStudy
        } else {
            self.recommendedStudy = availableRecommendedStudies.randomStudy(using: &randomNumberGenerator)
        }
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
}

public extension Collection where Element == Study {
    
    func randomStudy<R: RandomNumberGenerator>(using randomNumberGenerator: inout R) -> Study? {
        
        guard !isEmpty else {
            return nil
        }
        
        let next = randomNumberGenerator.next()
        let offset = Int(next % UInt64(count))
        let index = self.index(startIndex, offsetBy: offset)
        
        return self[index]
    }
    
}
