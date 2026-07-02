//
//  StudyConfigurationService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 02.07.26.
//

public protocol StudyConfigurationService {
    func isAvailable(for study: Study) async throws -> Bool?
}
