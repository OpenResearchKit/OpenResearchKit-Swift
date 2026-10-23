//
//  LongTermStudyCompletionAcknowledgementTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.10.26.
//

import Combine
import XCTest
@testable import OpenResearchKit

@MainActor
final class LongTermStudyCompletionAcknowledgementTests: XCTestCase {

    private var studiesToReset: [Study] = []
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        for study in studiesToReset {
            try? study.reset()
        }

        studiesToReset = []
        cancellables.removeAll()

        super.tearDown()
    }

    // MARK: - Expiry -

    func testStudyWithSurveyStaysActiveAndAwaitsSurveyAfterExpiry() {
        let (study, dateGenerator) = makeConsentedStudy()

        XCTAssertTrue(study.isActive)
        XCTAssertFalse(study.isAwaitingConclusionSurvey)
        XCTAssertFalse(study.isAwaitingCompletionAcknowledgement)

        dateGenerator.travel(by: 11)

        XCTAssertFalse(study.isActiveStudyPeriod)
        XCTAssertTrue(study.isActive)
        XCTAssertTrue(study.isAwaitingConclusionSurvey)
        XCTAssertFalse(study.isAwaitingCompletionAcknowledgement)
    }

    func testStudyWithoutSurveyAwaitsAcknowledgementAfterExpiry() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)

        dateGenerator.travel(by: 11)

        XCTAssertTrue(study.isActive)
        XCTAssertFalse(study.isAwaitingConclusionSurvey)
        XCTAssertTrue(study.isAwaitingCompletionAcknowledgement)
    }

    func testExpiryIsReachedExactlyAtTheIntendedEndDate() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)

        dateGenerator.travel(by: 10)

        XCTAssertTrue(study.isAwaitingCompletionAcknowledgement)
    }

    // MARK: - Conclusion Survey -

    func testSuccessfulSurveyRecordsOnlySurveyCompletion() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)

        study.handleConclusionSurveyResult(success: true)

        XCTAssertTrue(study.hasCompletedTerminationSurvey)
        XCTAssertFalse(study.isCompleted)
        XCTAssertTrue(study.isActive)
        XCTAssertFalse(study.isAwaitingConclusionSurvey)
        XCTAssertTrue(study.isAwaitingCompletionAcknowledgement)
    }

    func testFailedSurveyLeavesSurveyAndStudyPending() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)

        study.handleConclusionSurveyResult(success: false)

        XCTAssertFalse(study.hasCompletedTerminationSurvey)
        XCTAssertFalse(study.isCompleted)
        XCTAssertTrue(study.isAwaitingConclusionSurvey)
        XCTAssertFalse(study.acknowledgeCompletion())
    }

    // MARK: - Acknowledgement -

    func testAcknowledgementIsRejectedDuringStudyPeriod() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)
        dateGenerator.travel(by: 5)

        XCTAssertFalse(study.acknowledgeCompletion())
        XCTAssertFalse(study.isCompleted)
        XCTAssertTrue(study.isActive)
    }

    func testAcknowledgementIsRejectedWhileSurveyIsPending() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)

        XCTAssertFalse(study.acknowledgeCompletion())
        XCTAssertFalse(study.isCompleted)
        XCTAssertTrue(study.isActive)
    }

    func testAcknowledgementIsRejectedWithoutConsent() {
        let study = makeStudy()

        XCTAssertFalse(study.acknowledgeCompletion())
        XCTAssertFalse(study.isCompleted)
    }

    func testAcknowledgementIsRejectedAfterWithdrawal() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)
        dateGenerator.travel(by: 5)
        study.terminateParticipationImmediately()
        dateGenerator.travel(by: 6)

        XCTAssertFalse(study.isAwaitingCompletionAcknowledgement)
        XCTAssertFalse(study.acknowledgeCompletion())
        XCTAssertFalse(study.isCompleted)
        XCTAssertFalse(study.isActive)
    }

    func testAcknowledgementCompletesStudyAfterSurvey() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)
        study.handleConclusionSurveyResult(success: true)

        XCTAssertTrue(study.acknowledgeCompletion())

        XCTAssertTrue(study.isCompleted)
        XCTAssertEqual(study.completionDate, dateGenerator.generate())
        XCTAssertFalse(study.isActive)
        XCTAssertFalse(study.isAwaitingCompletionAcknowledgement)
        XCTAssertFalse(study.wasTerminatedBeforeCompletion)
    }

    func testAcknowledgementCompletesStudyWithoutSurvey() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)
        dateGenerator.travel(by: 11)

        XCTAssertTrue(study.acknowledgeCompletion())
        XCTAssertTrue(study.isCompleted)
        XCTAssertFalse(study.isActive)
        XCTAssertFalse(study.wasTerminatedBeforeCompletion)
    }

    func testRepeatedAcknowledgementKeepsOriginalCompletionDate() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)
        dateGenerator.travel(by: 11)
        study.acknowledgeCompletion()
        let completionDate = study.completionDate

        dateGenerator.travel(by: 100)

        XCTAssertTrue(study.acknowledgeCompletion())
        XCTAssertEqual(study.completionDate, completionDate)
    }

    func testCompletionPersistsAcrossStudyInstances() {
        let identifier = UUID().uuidString
        let (study, dateGenerator) = makeConsentedStudy(identifier: identifier, concludingSurveyURL: nil)
        dateGenerator.travel(by: 11)
        study.acknowledgeCompletion()

        let restoredStudy = makeStudy(identifier: identifier, concludingSurveyURL: nil, resetStoredState: false)
        restoredStudy.dateGenerator = dateGenerator

        XCTAssertTrue(restoredStudy.isCompleted)
        XCTAssertFalse(restoredStudy.isActive)
        XCTAssertFalse(restoredStudy.isAwaitingCompletionAcknowledgement)
    }

    func testAlreadyCompletedRecordStaysCompleted() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)

        // Records completed before the acknowledgement existed have a completion date.
        study.setCompleted()

        XCTAssertFalse(study.isActive)
        XCTAssertFalse(study.isAwaitingConclusionSurvey)
        XCTAssertFalse(study.isAwaitingCompletionAcknowledgement)
        XCTAssertTrue(study.acknowledgeCompletion())
    }

    // MARK: - Registry -

    func testRegistrySwitchesAwayAfterAcknowledgement() async {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)
        dateGenerator.travel(by: 11)
        let registry = StudyRegistry(
            studies: [study],
            studyConfigurationService: StubStudyConfigurationService()
        )

        XCTAssertTrue(registry.currentActiveStudy === study)

        let expectation = expectation(description: "Registry refreshed")
        expectation.assertForOverFulfill = false
        registry.objectWillChange
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        study.acknowledgeCompletion()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNil(registry.currentActiveStudy)
    }

    // MARK: - Default Behavior -

    func testDefaultStudyIsNeverAwaitingAcknowledgement() {
        let (study, dateGenerator) = makeConsentedStudy(requiresAcknowledgement: false)
        dateGenerator.travel(by: 11)

        XCTAssertTrue(study.isActive)
        XCTAssertFalse(study.isAwaitingConclusionSurvey)
        XCTAssertFalse(study.isAwaitingCompletionAcknowledgement)
        XCTAssertFalse(study.acknowledgeCompletion())
    }

    func testDefaultStudyCompletesAfterSuccessfulSurvey() {
        let (study, dateGenerator) = makeConsentedStudy(requiresAcknowledgement: false)
        dateGenerator.travel(by: 11)

        study.handleConclusionSurveyResult(success: true)

        XCTAssertTrue(study.hasCompletedTerminationSurvey)
        XCTAssertTrue(study.isCompleted)
        XCTAssertFalse(study.isActive)
    }

    func testDefaultStudyStaysPendingAfterFailedSurvey() {
        let (study, dateGenerator) = makeConsentedStudy(requiresAcknowledgement: false)
        dateGenerator.travel(by: 11)

        study.handleConclusionSurveyResult(success: false)

        XCTAssertFalse(study.hasCompletedTerminationSurvey)
        XCTAssertFalse(study.isCompleted)
        XCTAssertTrue(study.isActive)
    }

    func testDefaultStudyWithoutSurveyEndsWithStudyPeriod() {
        let (study, dateGenerator) = makeConsentedStudy(requiresAcknowledgement: false, concludingSurveyURL: nil)
        dateGenerator.travel(by: 11)

        XCTAssertFalse(study.isActive)
        XCTAssertFalse(study.isCompleted)
    }

    // MARK: - Survey Banner -

    func testConclusionBannerIsDueUntilSurveyIsCompleted() {
        let (study, dateGenerator) = makeConsentedStudy()

        XCTAssertNil(study.surveyBanner(at: dateGenerator.generate()))
        XCTAssertEqual(study.nextSurveyBannerChangeDate(after: dateGenerator.generate()), study.intendedStudyEndDate)

        dateGenerator.travel(by: 11)

        XCTAssertEqual(study.surveyBanner(at: dateGenerator.generate()), .completion)

        study.handleConclusionSurveyResult(success: true)

        XCTAssertTrue(study.isAwaitingCompletionAcknowledgement)
        XCTAssertNil(study.surveyBanner(at: dateGenerator.generate()))
        XCTAssertNil(study.nextSurveyBannerChangeDate(after: dateGenerator.generate()))
    }/Users/lennart/Documents/Development/one-sec/OpenResearchKit-Swift/Tests/OpenResearchKitTests/Models/Studies/LongTermStudyCompletionAcknowledgementTests.swift
    XCTAssertEqual(study.nextSurveyBannerChangeDate(after: dateGenerator.generate()), study.intendedStudyEndDate)

    func testFailedSurveyKeepsConclusionBannerDue() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)

        study.handleConclusionSurveyResult(success: false)

        XCTAssertEqual(study.surveyBanner(at: dateGenerator.generate()), .completion)
    }

    func testStudyWithoutSurveyShowsNoBannerWhileAwaitingAcknowledgement() {
        let (study, dateGenerator) = makeConsentedStudy(concludingSurveyURL: nil)
        dateGenerator.travel(by: 11)

        XCTAssertTrue(study.isAwaitingCompletionAcknowledgement)
        XCTAssertNil(study.surveyBanner(at: dateGenerator.generate()))
        XCTAssertNil(study.nextSurveyBannerChangeDate(after: dateGenerator.generate().addingTimeInterval(-20)))
    }

    func testAcknowledgedStudyShowsNoBanner() {
        let (study, dateGenerator) = makeConsentedStudy()
        dateGenerator.travel(by: 11)
        study.handleConclusionSurveyResult(success: true)

        XCTAssertTrue(study.acknowledgeCompletion())
        XCTAssertNil(study.surveyBanner(at: dateGenerator.generate()))
    }

    // MARK: - Helpers -

    private func makeConsentedStudy(
        identifier: String = UUID().uuidString,
        requiresAcknowledgement: Bool = true,
        concludingSurveyURL: URL? = URL(string: "https://example.com/conclusion")!
    ) -> (LongTermStudy, TimeTraveler) {
        let study = makeStudy(
            identifier: identifier,
            requiresAcknowledgement: requiresAcknowledgement,
            concludingSurveyURL: concludingSurveyURL
        )
        let dateGenerator = TimeTraveler()
        study.dateGenerator = dateGenerator
        study.store.update(Study.Keys.UserConsentDate, value: dateGenerator.generate())

        return (study, dateGenerator)
    }

    private func makeStudy(
        identifier: String = UUID().uuidString,
        requiresAcknowledgement: Bool = true,
        concludingSurveyURL: URL? = URL(string: "https://example.com/conclusion")!,
        resetStoredState: Bool = true
    ) -> LongTermStudy {
        let study: LongTermStudy
        let information = StudyInformation(
            title: "Acknowledgement Study",
            subtitle: "Acknowledgement Study",
            contactEmail: "test@example.com",
            image: nil
        )

        if requiresAcknowledgement {
            study = AcknowledgementTestStudy(
                studyIdentifier: identifier,
                studyInformation: information,
                uploadConfiguration: .dummy,
                duration: 10,
                introductorySurveyURL: URL(string: "https://example.com/intro")!,
                concludingSurveyURL: concludingSurveyURL
            )
        } else {
            study = QuietTestLongTermStudy(
                studyIdentifier: identifier,
                studyInformation: information,
                uploadConfiguration: .dummy,
                duration: 10,
                introductorySurveyURL: URL(string: "https://example.com/intro")!,
                concludingSurveyURL: concludingSurveyURL
            )
        }

        if resetStoredState {
            try? study.reset()
        }

        studiesToReset.append(study)

        return study
    }

}

private class QuietTestLongTermStudy: LongTermStudy {

    override func shouldHaveNotifications() -> Bool {
        false
    }

}

private final class AcknowledgementTestStudy: QuietTestLongTermStudy {

    override var requiresCompletionAcknowledgement: Bool {
        true
    }

}
