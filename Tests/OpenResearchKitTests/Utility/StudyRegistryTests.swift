//
//  StudyRegistryTests.swift
//  OpenResearchKit
//
//  Created by Codex on 09.04.26.
//

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
    
    func testRegistryRefreshesAfterConsent() {
        let study = makeDataDonationStudy()
        let registry = makeRegistry(studies: [study])
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        assertRegistryRefresh(on: registry) {
            self.giveConsent(to: study)
        }
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }
    
    func testRegistryRefreshesAfterDismissal() {
        let study = makeDataDonationStudy()
        let registry = makeRegistry(studies: [study])
        
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        assertRegistryRefresh(on: registry) {
            study.isDismissedByUser = true
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)
    }
    
    func testRegistryRefreshesAfterTerminationBeforeCompletion() {
        let study = makeDataDonationStudy()
        giveConsent(to: study)
        
        let registry = makeRegistry(studies: [study])
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        assertRegistryRefresh(on: registry) {
            study.terminateParticipationImmediately()
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }
    
    func testRegistryRefreshesWhenStudyIsCompletedViaSetCompleted() {
        let study = makeDataDonationStudy()
        giveConsent(to: study)
        
        let registry = makeRegistry(studies: [study])
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        assertRegistryRefresh(on: registry) {
            study.setCompleted()
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertTrue(registry.recommendedStudies.isEmpty)
        XCTAssertNil(registry.recommendedStudy)
    }
    
    func testRegistryRefreshesAfterTerminationSurveyCompletion() {
        let study = makeLongTermStudy(duration: 60)
        giveConsent(to: study, at: Date().addingTimeInterval(-120))
        
        let registry = makeRegistry(studies: [study])
        
        XCTAssertTrue(registry.currentActiveStudy === study)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
        
        assertRegistryRefresh(on: registry) {
            study.completeTerminationSurvey()
        }
        
        XCTAssertNil(registry.currentActiveStudy)
        XCTAssertEqual(registry.recommendedStudies.map(\.studyIdentifier), [study.studyIdentifier])
        XCTAssertTrue(registry.recommendedStudy === study)
    }
    
    func testRegistryDoesNotRerandomizeRecommendedStudyForNonEligibilityChanges() {
        let firstStudy = makeDataDonationStudy()
        let secondStudy = makeDataDonationStudy()
        let thirdStudy = makeDataDonationStudy()
        let generator = CountingRandomNumberGenerator(values: [0, 2, 1, 0])
        let registry = makeRegistry(studies: [firstStudy, secondStudy, thirdStudy], randomNumberGenerator: generator)
        
        guard let initialRecommendedStudy = registry.recommendedStudy else {
            XCTFail("Expected an initial recommended study.")
            return
        }
        
        XCTAssertEqual(generator.nextCallCount, 1)
        
        assertRegistryRefresh(on: registry) {
            firstStudy.markUploadSuccessful(newDate: Date())
        }
        
        XCTAssertEqual(generator.nextCallCount, 1)
        XCTAssertTrue(registry.recommendedStudy === initialRecommendedStudy)
        XCTAssertEqual(
            Set(registry.recommendedStudies.map(\.studyIdentifier)),
            Set([firstStudy.studyIdentifier, secondStudy.studyIdentifier, thirdStudy.studyIdentifier])
        )
    }
    
    // MARK: - Helpers -
    
    private func makeRegistry(
        studies: [Study],
        randomNumberGenerator: any RandomNumberGenerator = CountingRandomNumberGenerator(values: [0])
    ) -> StudyRegistry {
        StudyRegistry(studies: studies, randomNumberGenerator: randomNumberGenerator)
    }
    
    private func makeDataDonationStudy() -> QuietDataDonationStudy {
        let identifier = "study-registry-data-donation-\(UUID().uuidString)"
        
        let study = QuietDataDonationStudy(
            studyIdentifier: identifier,
            studyInformation: StudyInformation(
                title: "Data Donation",
                subtitle: "Donate your data for science.",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                fileSubmissionServer: URL(string: "https://example.com/upload")!,
                uploadFrequency: 3600,
                apiKey: "TEST_API_KEY"
            ),
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            participationIsPossible: true
        )
        
        studiesToReset.append(study)
        
        return study
    }
    
    private func makeLongTermStudy(duration: TimeInterval) -> QuietLongTermStudy {
        let identifier = "study-registry-long-term-\(UUID().uuidString)"
        
        let study = QuietLongTermStudy(
            studyIdentifier: identifier,
            studyInformation: StudyInformation(
                title: "Long Term Study",
                subtitle: "Track behavior over time.",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                fileSubmissionServer: URL(string: "https://example.com/upload")!,
                uploadFrequency: 3600,
                apiKey: "TEST_API_KEY"
            ),
            duration: duration,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            concludingSurveyURL: URL(string: "https://example.com/completion")!,
            participationIsPossible: true
        )
        
        studiesToReset.append(study)
        
        return study
    }
    
    private func giveConsent(to study: Study, at date: Date = Date()) {
        let expectation = expectation(description: "Study consent saved")
        
        study.saveUserConsentHasBeenGiven(consentTimestamp: date) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func assertRegistryRefresh(
        on registry: StudyRegistry,
        perform action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Registry refreshed")
        expectation.assertForOverFulfill = false
        
        registry.objectWillChange
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}

private final class QuietDataDonationStudy: DataDonationStudy {
    
    override func didTerminateParticipation(terminationDate: Date) {
        
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
