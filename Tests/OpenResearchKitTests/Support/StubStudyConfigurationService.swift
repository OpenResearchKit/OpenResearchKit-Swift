//
//  StubStudyConfigurationService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 02.07.26.
//

import Foundation
@testable import OpenResearchKit

final class StubStudyConfigurationService: StudyConfigurationService {

    var isAvailableByIdentifier: [String: Bool]
    var failingStudyIdentifiers: Set<String>
    private let defaultIsAvailable: Bool?

    init(
        isAvailableByIdentifier: [String: Bool] = [:],
        failingStudyIdentifiers: Set<String> = [],
        defaultIsAvailable: Bool? = nil
    ) {
        self.isAvailableByIdentifier = isAvailableByIdentifier
        self.failingStudyIdentifiers = failingStudyIdentifiers
        self.defaultIsAvailable = defaultIsAvailable
    }

    func isAvailable(for study: Study) async throws -> Bool? {
        if failingStudyIdentifiers.contains(study.studyIdentifier) {
            throw URLError(.notConnectedToInternet)
        }

        return isAvailableByIdentifier[study.studyIdentifier] ?? defaultIsAvailable
    }

}
