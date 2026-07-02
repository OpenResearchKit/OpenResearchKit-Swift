//
//  Collection+StudyRecommendations.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 02.07.26.
//

extension Collection where Element == Study {

    func locallyRecommendedStudies() -> [Study] {
        filter { study in
            guard !study.isDismissedByUser else { return false }
            guard !study.isCompleted else { return false }
            guard study.introductorySurveyURL != nil else { return false }

            return study.meetsRecommendationCriteria
        }
    }

    func randomizedRecommendations<R: RandomNumberGenerator>(using randomNumberGenerator: inout R) -> [Study] {
        var randomizedStudies = Array(self)

        guard randomizedStudies.count > 1 else {
            return randomizedStudies
        }

        for index in randomizedStudies.indices.dropLast() {
            let remainingCount = randomizedStudies.count - index
            let randomOffset = Int(randomNumberGenerator.next() % UInt64(remainingCount))
            randomizedStudies.swapAt(index, index + randomOffset)
        }

        return randomizedStudies
    }

}
