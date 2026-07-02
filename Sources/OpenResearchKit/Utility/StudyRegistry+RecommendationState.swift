//
//  StudyRegistry+RecommendationState.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 02.07.26.
//

extension StudyRegistry {

    public enum RecommendationState {

        case loading
        case loaded(recommendedStudies: [Study])
        case refreshing(recommendedStudies: [Study])

        var isLoading: Bool {
            switch self {
            case .loading, .refreshing:
                return true
            case .loaded:
                return false
            }
        }

        public var recommendedStudies: [Study] {
            switch self {
            case let .loaded(recommendedStudies),
                 let .refreshing(recommendedStudies):
                return recommendedStudies
            case .loading:
                return []
            }
        }

        var refreshStarted: RecommendationState {
            !recommendedStudies.isEmpty
                ? .refreshing(recommendedStudies: recommendedStudies)
                : .loading
        }

        func pruningRecommendations(to locallyRecommendedStudies: [Study]) -> RecommendationState {
            switch self {
            case .loading:
                return self
            case let .loaded(recommendedStudies):
                return .loaded(
                    recommendedStudies: Self.pruned(
                        recommendedStudies,
                        to: locallyRecommendedStudies
                    )
                )
            case let .refreshing(recommendedStudies):
                return .refreshing(
                    recommendedStudies: Self.pruned(
                        recommendedStudies,
                        to: locallyRecommendedStudies
                    )
                )
            }
        }

        private static func pruned(_ recommendedStudies: [Study], to locallyRecommendedStudies: [Study]) -> [Study] {
            let locallyRecommendedStudyIdentifiers = Set(locallyRecommendedStudies.map { ObjectIdentifier($0) })

            return recommendedStudies.filter { recommendedStudy in
                locallyRecommendedStudyIdentifiers.contains(ObjectIdentifier(recommendedStudy))
            }
        }

    }

}
