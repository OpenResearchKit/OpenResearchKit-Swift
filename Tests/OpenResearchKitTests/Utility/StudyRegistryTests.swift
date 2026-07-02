//
//  StudyRegistryTests.swift
//  OpenResearchKit
//
//  Created by Codex on 09.04.26.
//

import Foundation
import XCTest
import Combine
@testable import OpenResearchKit

@MainActor
final class StudyRegistryTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []
    private var studiesToReset: [Study] = []
    
    override func tearDown() {
        for study in studiesToReset {
            try? study.reset()
        }
        
        studiesToReset = []
        cancellables.removeAll()
        
        super.tearDown()
    }

    func testRecommendationsAreEmptyUntilRecommendationsAreRefreshed() {
        let study = makeDataDonationStudy()
        let registry = StudyRegistry(
            studies: [study],
            studyConfigurationService: StubStudyConfigurationService()
        )

        guard case let .loaded(stateRecommendedStudies) = registry.recommendationState else {
            XCTFail("Expected loaded recommendation state.")
            return
        }

        XCTAssertTrue(stateRecommendedStudies.isEmpty)
        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)
    }
    
    func testRegistryRefreshesAfterConsent() async {
        let study = makeDataDonationStudy()
        let registry = await makeRegistry(studies: [study])
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        await assertRegistryRefresh(on: registry) {
            await self.giveConsent(to: study)
        }
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }
    
    func testRegistryRefreshesAfterDismissal() async {
        let study = makeDataDonationStudy()
        let registry = await makeRegistry(studies: [study])
        
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.dismissedStudies.isEmpty)
        XCTAssertTrue(registry.recommendedStudy === study)
        
        await assertRegistryRefresh(on: registry) {
            study.isDismissedByUser = true
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertEqual(registry.dismissedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertNil(registry.recommendedStudy)
    }

    func testDismissedStudiesUpdatesAfterDismissal() async {
        let visibleStudy = makeDataDonationStudy()
        let dismissedStudy = makeDataDonationStudy()
        let registry = await makeRegistry(studies: [visibleStudy, dismissedStudy])

        XCTAssertTrue(registry.dismissedStudies.isEmpty)

        await assertRegistryRefresh(on: registry) {
            dismissedStudy.isDismissedByUser = true
        }

        XCTAssertEqual(registry.dismissedStudies.map(\.studyIdentifier), [dismissedStudy.studyIdentifier])
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [visibleStudy.studyIdentifier])
    }

    func testRegistryExcludesStudiesWithoutIntroSurveyFromRecommendations() async {
        let studyWithoutIntroSurvey = makeDataDonationStudy(introductorySurveyURL: nil)
        let studyWithIntroSurvey = makeDataDonationStudy()
        let registry = await makeRegistry(studies: [studyWithoutIntroSurvey, studyWithIntroSurvey])

        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [studyWithIntroSurvey.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === studyWithIntroSurvey)
    }

    func testRefreshChecksRemoteAvailabilityOnlyForLocallyRecommendedStudies() async {
        let visibleStudy = makeDataDonationStudy()
        let dismissedStudy = makeDataDonationStudy()
        let completedStudy = makeDataDonationStudy()
        let studyWithoutIntroSurvey = makeDataDonationStudy(introductorySurveyURL: nil)
        let ineligibleStudy = makeDataDonationStudy(participationIsPossible: false)
        let removedStudy = makeRemovedFromRecommendationsStudy()
        let expiredStudy = makeExpiredStudy()
        let service = StubStudyConfigurationService()

        dismissedStudy.isDismissedByUser = true
        completedStudy.setCompleted()

        let registry = await makeRegistry(
            studies: [
                visibleStudy,
                dismissedStudy,
                completedStudy,
                studyWithoutIntroSurvey,
                ineligibleStudy,
                removedStudy,
                expiredStudy,
            ],
            studyConfigurationService: service
        )

        XCTAssertEqual(service.requestedStudyIdentifiers, [visibleStudy.studyIdentifier])
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [visibleStudy.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === visibleStudy)
    }

    func testRegistryChecksLocalCandidatesInRandomizedOrderAndUsesFirstAvailableStudy() async {
        let firstStudy = makeDataDonationStudy()
        let secondStudy = makeDataDonationStudy()
        let thirdStudy = makeDataDonationStudy()
        let service = StubStudyConfigurationService(
            isAvailableByIdentifier: [
                secondStudy.studyIdentifier: true,
                thirdStudy.studyIdentifier: false,
            ]
        )
        let generator = CountingRandomNumberGenerator(values: [2, 1])
        let registry = await makeRegistry(
            studies: [firstStudy, secondStudy, thirdStudy],
            randomNumberGenerator: generator,
            studyConfigurationService: service
        )

        XCTAssertEqual(
            service.requestedStudyIdentifiers,
            [thirdStudy.studyIdentifier, firstStudy.studyIdentifier, secondStudy.studyIdentifier]
        )
        XCTAssertEqual(
            registry.recommendedStudies.map(\.studyIdentifier),
            [firstStudy.studyIdentifier, secondStudy.studyIdentifier]
        )
        XCTAssertTrue(registry.recommendedStudy === firstStudy)
    }

    func testRegistryExcludesRemotelyUnavailableStudiesFromRecommendations() async {
        let unavailableStudy = makeDataDonationStudy()
        let availableStudy = makeDataDonationStudy()
        let service = StubStudyConfigurationService(
            isAvailableByIdentifier: [unavailableStudy.studyIdentifier: false]
        )
        let registry = await makeRegistry(
            studies: [unavailableStudy, availableStudy],
            studyConfigurationService: service
        )

        guard case let .loaded(stateRecommendedStudies) = registry.recommendationState else {
            XCTFail("Expected loaded recommendation state.")
            return
        }
        XCTAssertEqual(stateRecommendedStudies.map(\.studyIdentifier), [availableStudy.studyIdentifier])
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [availableStudy.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === availableStudy)
    }

    func testRegistryIncludesStudyWhenRemoteConfigurationIsMissing() async {
        let study = makeDataDonationStudy()
        let registry = await makeRegistry(studies: [study], studyConfigurationService: StubStudyConfigurationService())

        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }

    func testRegistryReturnsNoRecommendationsWhenAllRemoteCandidatesAreUnavailable() async {
        let firstStudy = makeDataDonationStudy()
        let secondStudy = makeDataDonationStudy()
        let service = StubStudyConfigurationService(
            isAvailableByIdentifier: [
                firstStudy.studyIdentifier: false,
                secondStudy.studyIdentifier: false,
            ]
        )
        let registry = await makeRegistry(studies: [firstStudy, secondStudy], studyConfigurationService: service)

        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)
    }

    func testRegistryKeepsPreviousIsAvailableValueWhenRefreshFails() async {
        let study = makeDataDonationStudy()
        let service = StubStudyConfigurationService(
            isAvailableByIdentifier: [study.studyIdentifier: false]
        )
        let registry = await makeRegistry(studies: [study], studyConfigurationService: service)

        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)

        service.failingStudyIdentifiers = [study.studyIdentifier]
        await registry.refreshRecommendations()

        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)

        service.failingStudyIdentifiers = []
        service.isAvailableByIdentifier[study.studyIdentifier] = true
        await registry.refreshRecommendations()

        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }

    func testRegistryFallsBackToLocalRecommendationWhenRefreshFailsWithoutCachedAvailability() async {
        let study = makeDataDonationStudy()
        let service = StubStudyConfigurationService(failingStudyIdentifiers: [study.studyIdentifier])
        let registry = await makeRegistry(studies: [study], studyConfigurationService: service)

        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }

    func testRegisteringStudyKeepsExistingRecommendationsWithoutAddingNewCandidates() async {
        let recommendedStudy = makeDataDonationStudy()
        let unavailableStudy = makeDataDonationStudy()
        let newlyRegisteredStudy = makeDataDonationStudy()
        let service = StubStudyConfigurationService(
            isAvailableByIdentifier: [unavailableStudy.studyIdentifier: false]
        )
        let registry = await makeRegistry(
            studies: [recommendedStudy, unavailableStudy],
            studyConfigurationService: service
        )

        XCTAssertEqual(
            registry.recommendedStudies.map(\.studyIdentifier),
            [recommendedStudy.studyIdentifier]
        )

        registry.registerStudies([newlyRegisteredStudy])

        XCTAssertEqual(
            registry.recommendedStudies.map(\.studyIdentifier),
            [recommendedStudy.studyIdentifier]
        )
        XCTAssertTrue(registry.recommendedStudy === recommendedStudy)
        XCTAssertEqual(
            service.requestedStudyIdentifiers,
            [recommendedStudy.studyIdentifier, unavailableStudy.studyIdentifier]
        )
    }
    
    func testRegistryRefreshesAfterTerminationBeforeCompletion() async {
        let study = makeDataDonationStudy()
        await giveConsent(to: study)
        
        let registry = await makeRegistry(studies: [study])
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        await assertRegistryRefresh(on: registry) {
            study.terminateParticipationImmediately()
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }
    
    func testRegistryRefreshesWhenStudyIsCompletedViaSetCompleted() async {
        let study = makeDataDonationStudy()
        await giveConsent(to: study)
        
        let registry = await makeRegistry(studies: [study])
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        await assertRegistryRefresh(on: registry) {
            study.setCompleted()
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)
    }
    
    func testRegistryRefreshesAfterTerminationSurveyCompletion() async {
        let study = makeLongTermStudy(duration: 60)
        await giveConsent(to: study, at: Date().addingTimeInterval(-120))
        
        let registry = await makeRegistry(studies: [study])
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        await assertRegistryRefresh(on: registry) {
            study.completeTerminationSurvey()
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }
    
    func testRegistryDoesNotRerandomizeRecommendedStudyForNonEligibilityChanges() async {
        let firstStudy = makeDataDonationStudy()
        let secondStudy = makeDataDonationStudy()
        let thirdStudy = makeDataDonationStudy()
        let generator = CountingRandomNumberGenerator(values: [0, 2, 1, 0])
        let registry = await makeRegistry(studies: [firstStudy, secondStudy, thirdStudy], randomNumberGenerator: generator)
        
        guard let initialRecommendedStudy = registry.recommendedStudy else {
            XCTFail("Expected an initial recommended study.")
            return
        }
        
        XCTAssertEqual(generator.nextCallCount, 2)
        
        await assertRegistryRefresh(on: registry) {
            firstStudy.markUploadSuccessful(newDate: Date())
        }
        
        XCTAssertEqual(generator.nextCallCount, 2)
        XCTAssertTrue(registry.recommendedStudy === initialRecommendedStudy)
        XCTAssertEqual(
            Set(registry.recommendedStudies.map(\.studyIdentifier)),
            Set([firstStudy.studyIdentifier, secondStudy.studyIdentifier, thirdStudy.studyIdentifier])
        )
    }
    
    // MARK: - Helpers -
    
    private func makeRegistry(
        studies: [Study],
        randomNumberGenerator: any RandomNumberGenerator = CountingRandomNumberGenerator(values: [0]),
        studyConfigurationService: any StudyConfigurationService = StubStudyConfigurationService()
    ) async -> StudyRegistry {
        let registry = StudyRegistry(
            studies: studies,
            randomNumberGenerator: randomNumberGenerator,
            studyConfigurationService: studyConfigurationService
        )
        await registry.refreshRecommendations()
        return registry
    }
    
    private func makeDataDonationStudy(
        introductorySurveyURL: URL? = URL(string: "https://example.com/intro")!,
        participationIsPossible: Bool = true
    ) -> QuietDataDonationStudy {
        registerStudy(QuietDataDonationStudy(
            studyIdentifier: "study-registry-data-donation-\(UUID().uuidString)",
            studyInformation: makeStudyInformation(title: "Data Donation"),
            uploadConfiguration: makeUploadConfiguration(),
            introductorySurveyURL: introductorySurveyURL,
            participationIsPossible: participationIsPossible
        ))
    }

    private func makeRemovedFromRecommendationsStudy() -> RemovedFromRecommendationsDataDonationStudy {
        let study = RemovedFromRecommendationsDataDonationStudy(
            studyIdentifier: "study-registry-removed-\(UUID().uuidString)",
            studyInformation: makeStudyInformation(title: "Removed Study"),
            uploadConfiguration: makeUploadConfiguration(),
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            participationIsPossible: true
        )

        return registerStudy(study)
    }

    private func makeExpiredStudy() -> ExpiredDataDonationStudy {
        let study = ExpiredDataDonationStudy(
            studyIdentifier: "study-registry-expired-\(UUID().uuidString)",
            studyInformation: makeStudyInformation(title: "Expired Study"),
            uploadConfiguration: makeUploadConfiguration(),
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            participationIsPossible: true
        )

        return registerStudy(study)
    }
    
    private func makeLongTermStudy(duration: TimeInterval) -> QuietLongTermStudy {
        registerStudy(QuietLongTermStudy(
            studyIdentifier: "study-registry-long-term-\(UUID().uuidString)",
            studyInformation: makeStudyInformation(title: "Long Term Study"),
            uploadConfiguration: makeUploadConfiguration(),
            duration: duration,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            concludingSurveyURL: URL(string: "https://example.com/completion")!,
            participationIsPossible: true
        ))
    }

    private func makeStudyInformation(title: String) -> StudyInformation {
        StudyInformation(
            title: title,
            subtitle: "Donate your data for science.",
            contactEmail: "test@example.com",
            image: nil
        )
    }

    private func makeUploadConfiguration() -> UploadConfiguration {
        UploadConfiguration(
            serverURL: URL(string: "https://example.com/upload")!,
            uploadFrequency: 3600,
            apiKey: "TEST_API_KEY"
        )
    }

    private func registerStudy<StudyType: Study>(_ study: StudyType) -> StudyType {
        studiesToReset.append(study)

        return study
    }
    
    private func giveConsent(to study: Study, at date: Date = Date()) async {
        let expectation = expectation(description: "Study consent saved")
        
        study.saveUserConsentHasBeenGiven(consentTimestamp: date) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    private func assertRegistryRefresh(
        on registry: StudyRegistry,
        perform action: () async -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let expectation = expectation(description: "Registry refreshed")
        expectation.assertForOverFulfill = false
        
        registry.objectWillChange
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await action()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
}

private class QuietDataDonationStudy: DataDonationStudy {
    
    override func shouldHaveNotifications() -> Bool {
        false
    }
    
    override func didTerminateParticipation(terminationDate: Date) {
        
    }
    
}

private final class RemovedFromRecommendationsDataDonationStudy: QuietDataDonationStudy {

    override func removeFromRecommendations() -> Bool {
        true
    }

}

private final class ExpiredDataDonationStudy: QuietDataDonationStudy {

    override var hasExpired: Bool {
        true
    }

}

private final class QuietLongTermStudy: LongTermStudy {
    
    override func shouldHaveNotifications() -> Bool {
        false
    }
    
    override func didTerminateParticipation(terminationDate: Date) {
        
    }
    
}

private final class CountingRandomNumberGenerator: RandomNumberGenerator {
    
    private let values: [UInt64]
    private var currentIndex: Int = 0
    
    private(set) var nextCallCount: Int = 0
    
    init(values: [UInt64]) {
        self.values = values.isEmpty ? [0] : values
    }
    
    func next() -> UInt64 {
        let value = values[currentIndex]
        
        nextCallCount += 1
        currentIndex = (currentIndex + 1) % values.count
        
        return value
    }
    
}
