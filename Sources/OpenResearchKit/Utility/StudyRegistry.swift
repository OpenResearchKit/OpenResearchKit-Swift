//
//  File.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 05.03.26.
//

import Foundation
import SwiftUI
import Combine
import OSLog

public class StudyRegistry: ObservableObject {
    
    public static let shared = StudyRegistry()
    
    // MARK: - Registry -
    
    public private(set) var studies: [Study] = [] {
        didSet {
            pruneAvailabilityForRegisteredStudies()
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
        recommendationState.recommendedStudies
    }

    public var dismissedStudies: [Study] {
        Study.filterDismissed(studies: studies)
    }

    public private(set) var recommendationState: RecommendationState = .loaded(
        recommendedStudies: []
    )

    public var recommendedStudy: Study? {
        recommendedStudies.first
    }
    
    private var isAvailableByStudyIdentifier: [String: Bool] = [:]
    private var randomNumberGenerator: any RandomNumberGenerator
    private let studyConfigurationService: any StudyConfigurationService
    private var studyObserverCancellables: [ObjectIdentifier: AnyCancellable] = [:]
    
    public init(
        studies: [Study] = [],
        randomNumberGenerator: any RandomNumberGenerator = SystemRandomNumberGenerator(),
        studyConfigurationService: any StudyConfigurationService = RemoteStudyConfigurationService()
    ) {
        self.studies = studies
        self.randomNumberGenerator = randomNumberGenerator
        self.studyConfigurationService = studyConfigurationService
        self.syncStudyObservers()
        self.refreshDerivedState()
    }
    
    // MARK: - Actions -
    
    public func registerStudies(_ studies: [Study]) {
        self.studies.append(contentsOf: studies)
    }

    @MainActor
    public func refreshRecommendations() async {
        guard !recommendationState.isLoading else { return }
        let stateBeforeRefresh = recommendationState

        recommendationState = recommendationState.refreshStarted
        publishRegistryChange()

        let localCandidates = studies
            .locallyRecommendedStudies()
            .randomizedRecommendations(using: &randomNumberGenerator)

        do {
            let remotelyAvailableStudies = try await remotelyAvailableStudies(from: localCandidates)
            pruneAvailabilityForRegisteredStudies()
            recommendationState = .loaded(
                recommendedStudies: remotelyAvailableStudies
            )
            refreshDerivedState()
        } catch is CancellationError {
            recommendationState = stateBeforeRefresh
            publishRegistryChange()
        } catch {
            Logger.research.error("Unexpected recommendation refresh failure: \(String(describing: error), privacy: .public)")
            recommendationState = stateBeforeRefresh
            publishRegistryChange()
        }
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
        recommendationState = recommendationState.pruningRecommendations(
            to: studies.locallyRecommendedStudies()
        )
        publishRegistryChange()
    }

    @MainActor
    private func remotelyAvailableStudies(from studies: [Study]) async throws -> [Study] {
        var availableStudies: [Study] = []

        for study in studies {
            if try await isRecommendedAfterRemoteAvailabilityCheck(study) {
                availableStudies.append(study)
            }
        }

        return availableStudies
    }

    @MainActor
    private func isRecommendedAfterRemoteAvailabilityCheck(_ study: Study) async throws -> Bool {
        do {
            try Task.checkCancellation()

            if let isAvailable = try await studyConfigurationService.isAvailable(for: study) {
                isAvailableByStudyIdentifier[study.studyIdentifier] = isAvailable
                return isAvailable
            }

            isAvailableByStudyIdentifier.removeValue(forKey: study.studyIdentifier)
            return true
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Logger.research.error("Failed to refresh recommendation availability for study \(study.studyIdentifier, privacy: .public): \(String(describing: error), privacy: .public)")

            return isAvailableByStudyIdentifier[study.studyIdentifier] ?? true
        }
    }

    private func pruneAvailabilityForRegisteredStudies() {
        let registeredStudyIdentifiers = Set(studies.map(\.studyIdentifier))
        isAvailableByStudyIdentifier = isAvailableByStudyIdentifier.filter { identifier, _ in
            registeredStudyIdentifiers.contains(identifier)
        }
    }

    private func publishRegistryChange() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
}
