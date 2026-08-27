//
//  LongTermStudyTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 12.09.25.
//

import XCTest
@testable import OpenResearchKit

extension UploadConfiguration {
    
    static let dummy: UploadConfiguration = .init(
        serverURL: URL(string: "https://example.org/upload")!,
        uploadFrequency: 60 * 60 * 24,
        apiKey: ""
    )
    
}

final class LongTermStudyTests: XCTestCase {
    
    // MARK: - Tests
    
    func testStudyInitialization() {
        let study = createLongTermStudy()
        
        XCTAssertEqual(study.studyInformation.title, "Test Study")
        XCTAssertEqual(study.studyInformation.description, "Test Subtitle")
        XCTAssertEqual(study.duration, 10)
        XCTAssertEqual(study.studyInformation.contactEmail, "test@example.com")
        XCTAssertEqual(study.uploadConfiguration.apiKey, "test")
        XCTAssertEqual(study.uploadConfiguration.uploadFrequency, 60)
    }

    func testLongTermStudyAbsoluteDateInitializerUsesPersistedConsentDate() {
        let studyIdentifier = UUID().uuidString
        let consentDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let store = StudyKeyValueStore(
            studyIdentifier: studyIdentifier,
            appGroup: nil
        )
        store.update(Study.Keys.UserConsentDate, value: consentDate)

        let study = LongTermStudy(
            studyIdentifier: studyIdentifier,
            studyInformation: makeStudyInformation(),
            uploadConfiguration: uploadConfiguration,
            studyEndDate: consentDate.addingTimeInterval(100),
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            concludingSurveyURL: URL(string: "https://example.com/conclusion")!
        )
        defer { try? study.reset() }

        XCTAssertEqual(study.duration, 100)
    }
    
    func testEmptyAdditionalQueryItems() {
        let study = createLongTermStudy()
        
        study.additionalQueryItems = { _ in [] }
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertFalse(url!.absoluteString.contains("&="))
    }
    
    func testStudyBuildsCompletionSurveyUrl() {
        let study = createLongTermStudy()
        
        let url = study.surveyUrl(for: .completion)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/conclusion"))
    }
    
    func testStudyBuildsMidSurveyUrl() {
        
        let study = createLongTermMidStudy()
        defer { try? study.reset() }
        
        let url = study.surveyUrl(for: .mid)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        XCTAssertTrue(url!.absoluteString.contains("https://example.com/mid"))
    }

    // MARK: - Mid-study surveys

    func testPluralMidSurveyInitializerRetainsAllSurveys() {
        let surveys = [
            makeMidSurvey(path: "mid/first", showAfter: 10),
            makeMidSurvey(path: "mid/second", showAfter: 20),
        ]
        let study = createLongTermMidStudy(midStudySurveys: surveys)
        defer { try? study.reset() }

        XCTAssertEqual(study.midStudySurveys.count, 2)
        XCTAssertEqual(study.midStudySurveys.map(\.url), surveys.map(\.url))
        XCTAssertEqual(study.midStudySurveys.map(\.schedule), surveys.map(\.schedule))
    }

    func testFixedDateInitializerUsesPersistedConsentDateAsReference() {
        let studyIdentifier = UUID().uuidString
        let consentDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let firstSurveyDate = consentDate.addingTimeInterval(10)
        let firstSurveyExpirationDate = consentDate.addingTimeInterval(15)
        let firstSurveyDuration = firstSurveyExpirationDate.timeIntervalSince(firstSurveyDate)
        let secondSurveyDate = consentDate.addingTimeInterval(20)
        let studyEndDate = consentDate.addingTimeInterval(100)
        let store = StudyKeyValueStore(
            studyIdentifier: studyIdentifier,
            appGroup: nil
        )
        store.update(Study.Keys.UserConsentDate, value: consentDate)

        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: studyIdentifier,
            studyInformation: makeStudyInformation(),
            uploadConfiguration: uploadConfiguration,
            studyEndDate: studyEndDate,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            midStudySurveys: [
                MidStudySurvey(
                    id: "first",
                    schedule: .fixedDates(
                        availableAt: firstSurveyDate,
                        expiresAfter: firstSurveyDuration
                    ),
                    url: URL(string: "https://example.com/mid/first")!
                ),
                MidStudySurvey(
                    id: "second",
                    schedule: .fixedDates(
                        availableAt: secondSurveyDate,
                        expiresAfter: nil
                    ),
                    url: URL(string: "https://example.com/mid/second")!
                )
            ],
            concludingSurveyURL: URL(string: "https://example.com/conclusion")!
        )
        defer { try? study.reset() }

        XCTAssertEqual(study.duration, 100)
        XCTAssertEqual(study.midStudySurveys.map(\.id), ["first", "second"])
        XCTAssertEqual(
            study.midStudySurveys.map(\.schedule),
            [
                .fixedDates(
                    availableAt: firstSurveyDate,
                    expiresAfter: firstSurveyDuration
                ),
                .fixedDates(
                    availableAt: secondSurveyDate,
                    expiresAfter: nil
                )
            ]
        )
    }

    func testFixedDateInitializerKeepsConfiguredDatesAfterConsent() {
        let studyIdentifier = UUID().uuidString
        let initializationDate = Date.now
        let consentDate = initializationDate.addingTimeInterval(25)
        let firstSurveyDate = initializationDate.addingTimeInterval(100)
        let studyEndDate = initializationDate.addingTimeInterval(200)

        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: studyIdentifier,
            studyInformation: makeStudyInformation(),
            uploadConfiguration: uploadConfiguration,
            studyEndDate: studyEndDate,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            midStudySurveys: [
                MidStudySurvey(
                    schedule: .fixedDates(
                        availableAt: firstSurveyDate,
                        expiresAfter: nil
                    ),
                    url: URL(string: "https://example.com/mid")!
                )
            ],
            concludingSurveyURL: URL(string: "https://example.com/conclusion")!
        )
        defer { try? study.reset() }
        study.store.update(Study.Keys.UserConsentDate, value: consentDate)

        XCTAssertEqual(
            study.midStudySurveyAvailabilityDate(
                for: study.midStudySurveys[0]
            ),
            firstSurveyDate
        )
        XCTAssertEqual(study.intendedStudyEndDate, studyEndDate)
    }

    func testSingularMidSurveyInitializerWrapsSurveyForCompatibility() {
        let survey = makeMidSurvey(path: "mid/legacy", showAfter: 10)
        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: UUID().uuidString,
            studyInformation: makeStudyInformation(),
            uploadConfiguration: uploadConfiguration,
            duration: 100,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            midStudySurvey: survey,
            concludingSurveyURL: URL(string: "https://example.com/conclusion")!
        )
        defer { try? study.reset() }

        XCTAssertEqual(study.midStudySurveys.count, 1)
        XCTAssertEqual(study.midStudySurveys.first?.url, survey.url)
        XCTAssertEqual(study.midStudySurveys.first?.schedule, survey.schedule)
    }

    func testEmptyMidSurveyArrayBehavesLikeLongTermStudyWithoutMidSurveys() {
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: []
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)

        XCTAssertTrue(study.isActive)
        XCTAssertFalse(study.hasCompletedMidSurvey)
        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertNil(study.surveyUrl(for: .mid))
    }

    func testMidSurveyBecomesDueAtExactBoundaryAndAdvancesAfterCompletion() {
        let firstSurvey = makeMidSurvey(path: "mid/first", showAfter: 10)
        let secondSurvey = makeMidSurvey(path: "mid/second", showAfter: 20)
        let study = createLongTermMidStudy(midStudySurveys: [firstSurvey, secondSurvey])
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)

        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertFalse(study.hasCompletedMidSurvey)

        dateGenerator.travel(by: 9)
        XCTAssertNil(study.midStudySurveyToDisplay)

        dateGenerator.travel(by: 1)
        XCTAssertEqual(study.midStudySurveyToDisplay?.id, firstSurvey.id)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/first")

        study.completeMidSurvey()

        XCTAssertFalse(study.hasCompletedMidSurvey)
        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/second")

        dateGenerator.travel(by: 10)
        XCTAssertEqual(study.midStudySurveyToDisplay?.id, secondSurvey.id)

        study.completeMidSurvey()

        XCTAssertTrue(study.hasCompletedMidSurvey)
        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertNil(study.surveyUrl(for: .mid))
    }

    func testEachMidSurveyReportsItsOwnCompletionState() {
        let firstSurvey = makeMidSurvey(path: "mid/first", showAfter: 10)
        let secondSurvey = makeMidSurvey(path: "mid/second", showAfter: 20)
        let study = createLongTermMidStudy(
            midStudySurveys: [firstSurvey, secondSurvey]
        )
        defer { try? study.reset() }

        XCTAssertEqual(
            study.midStudySurveys.map(\.hasBeenCompleted),
            [false, false]
        )

        study.completeMidSurvey(identifier: firstSurvey.id)

        XCTAssertEqual(
            study.midStudySurveys.map(\.hasBeenCompleted),
            [true, false]
        )

        study.completeMidSurvey(identifier: secondSurvey.id)

        XCTAssertEqual(
            study.midStudySurveys.map(\.hasBeenCompleted),
            [true, true]
        )
    }

    func testMidSurveyIsAvailableUntilItsExactExpirationBoundary() {
        let survey = makeMidSurvey(
            path: "mid/expiring",
            showAfter: 10,
            expiresAfter: 10
        )
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: [survey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)

        dateGenerator.travel(by: 9)
        XCTAssertNil(study.midStudySurveyToDisplay)

        dateGenerator.travel(by: 1)
        XCTAssertEqual(study.midStudySurveyToDisplay?.id, survey.id)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/expiring")

        dateGenerator.travel(by: 9)
        XCTAssertEqual(study.midStudySurveyToDisplay?.id, survey.id)

        dateGenerator.travel(by: 1)
        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertNil(study.surveyUrl(for: .mid))
        XCTAssertFalse(study.hasCompletedMidSurvey)
        XCTAssertFalse(study.midStudySurveys[0].hasBeenCompleted)
        XCTAssertTrue(study.hasResolvedMidStudySurveys)
        XCTAssertTrue(study.isActive)
    }

    func testCompletingAllMidSurveysDoesNotDeactivateStudy() {
        let survey = makeMidSurvey(path: "mid", showAfter: 10)
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: [survey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        dateGenerator.travel(by: 10)
        study.completeMidSurvey()

        XCTAssertTrue(study.hasCompletedMidSurvey)
        XCTAssertTrue(study.hasResolvedMidStudySurveys)
        XCTAssertTrue(study.isActive)

        dateGenerator.travel(by: 91)
        XCTAssertTrue(study.isActive)

        study.completeTerminationSurvey()
        XCTAssertFalse(study.isActive)
    }

    func testMidSurveyDisplayDecisionUsesOneCurrentDateSample() {
        let consentDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let dateGenerator = CountingDateGenerator(
            date: consentDate.addingTimeInterval(15)
        )
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: [
                makeMidSurvey(
                    path: "mid/expiring",
                    showAfter: 10,
                    expiresAfter: 20
                )
            ]
        )
        defer { try? study.reset() }
        study.dateGenerator = dateGenerator
        study.store.update(Study.Keys.UserConsentDate, value: consentDate)

        XCTAssertNotNil(study.midStudySurveyToDisplay)
        XCTAssertEqual(dateGenerator.generationCount, 1)
    }

    func testExpiredMidSurveyIsSkippedWithoutBlockingLaterSurvey() {
        let firstSurvey = makeMidSurvey(
            path: "mid/expired",
            showAfter: 10,
            expiresAfter: 5
        )
        let secondSurvey = makeMidSurvey(
            path: "mid/next",
            showAfter: 20,
            expiresAfter: 10
        )
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: [firstSurvey, secondSurvey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        dateGenerator.travel(by: 15)

        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/next")

        dateGenerator.travel(by: 5)

        XCTAssertEqual(study.midStudySurveyToDisplay?.id, secondSurvey.id)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/next")
    }

    func testExpiredMidSurveyCannotBeCompletedByCapturedCallback() {
        let firstSurvey = makeMidSurvey(
            path: "mid/expired",
            showAfter: 10,
            expiresAfter: 5
        )
        let secondSurvey = makeMidSurvey(path: "mid/next", showAfter: 20)
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: [firstSurvey, secondSurvey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        dateGenerator.travel(by: 10)
        let capturedIdentifier = study.nextMidStudySurveyIdentifier

        dateGenerator.travel(by: 5)
        study.completeMidSurvey(identifier: capturedIdentifier)

        XCTAssertFalse(study.hasCompletedMidSurvey)
        let completedIdentifiers = study.store.get(
            Study.Keys.CompletedMidStudySurveyIdentifiers,
            type: [String].self
        ) ?? []
        XCTAssertFalse(
            completedIdentifiers.contains(firstSurvey.completionIdentifier)
        )
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/next")
    }

    func testCompletingMidSurveyBeforeExpirationRemainsCompleted() {
        let survey = makeMidSurvey(
            path: "mid/expiring",
            showAfter: 10,
            expiresAfter: 10
        )
        let study = createLongTermMidStudy(
            duration: 100,
            midStudySurveys: [survey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        dateGenerator.travel(by: 19)
        study.completeMidSurvey()
        dateGenerator.travel(by: 1)

        XCTAssertTrue(study.hasCompletedMidSurvey)
        XCTAssertTrue(study.midStudySurveys[0].hasBeenCompleted)
        XCTAssertTrue(study.hasResolvedMidStudySurveys)
        XCTAssertNil(study.surveyUrl(for: .mid))
    }

    func testOverdueMidSurveysArePresentedOldestFirstRegardlessOfInputOrder() {
        let lateSurvey = makeMidSurvey(path: "mid/late", showAfter: 30)
        let earlySurvey = makeMidSurvey(path: "mid/early", showAfter: 10)
        let middleSurvey = makeMidSurvey(path: "mid/middle", showAfter: 20)
        let study = createLongTermMidStudy(
            midStudySurveys: [lateSurvey, earlySurvey, middleSurvey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        dateGenerator.travel(by: 31)

        XCTAssertEqual(study.midStudySurveyToDisplay?.id, earlySurvey.id)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/early")

        study.completeMidSurvey()

        XCTAssertEqual(
            study.midStudySurveys.map(\.hasBeenCompleted),
            [false, true, false]
        )
        XCTAssertEqual(study.midStudySurveyToDisplay?.id, middleSurvey.id)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/middle")

        study.completeMidSurvey()

        XCTAssertEqual(study.midStudySurveyToDisplay?.id, lateSurvey.id)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/late")

        study.completeMidSurvey()

        XCTAssertTrue(study.hasCompletedMidSurvey)
        XCTAssertNil(study.midStudySurveyToDisplay)
        XCTAssertNil(study.surveyUrl(for: .mid))
    }

    func testMidSurveyUrlIncludesQueryItemsAndAdvancesToNextSurvey() throws {
        let study = createLongTermMidStudy(
            midStudySurveys: [
                makeMidSurvey(path: "mid/first", showAfter: 10),
                makeMidSurvey(path: "mid/second", showAfter: 20),
            ],
            additionalQueryItems: { surveyType in
                surveyType == .mid
                    ? [URLQueryItem(name: "version", value: "1.0")]
                    : []
            }
        )
        defer { try? study.reset() }

        let firstURL = try XCTUnwrap(study.surveyUrl(for: .mid))
        let firstComponents = try XCTUnwrap(
            URLComponents(url: firstURL, resolvingAgainstBaseURL: false)
        )

        XCTAssertEqual(firstComponents.path, "/mid/first")
        XCTAssertTrue(
            firstComponents.queryItems?.contains(
                URLQueryItem(name: "uuid", value: study.userIdentifier)
            ) == true
        )
        XCTAssertTrue(
            firstComponents.queryItems?.contains(
                URLQueryItem(name: "version", value: "1.0")
            ) == true
        )

        study.completeMidSurvey()

        let secondURL = try XCTUnwrap(study.surveyUrl(for: .mid))
        let secondComponents = try XCTUnwrap(
            URLComponents(url: secondURL, resolvingAgainstBaseURL: false)
        )

        XCTAssertEqual(secondComponents.path, "/mid/second")
        XCTAssertTrue(
            secondComponents.queryItems?.contains(
                URLQueryItem(name: "uuid", value: study.userIdentifier)
            ) == true
        )
        XCTAssertTrue(
            secondComponents.queryItems?.contains(
                URLQueryItem(name: "version", value: "1.0")
            ) == true
        )
    }

    func testMidSurveyCompletionPersistsByIdentityAcrossConfigurationReordering() {
        let studyIdentifier = UUID().uuidString
        let firstSurvey = makeMidSurvey(path: "mid/first", showAfter: 10)
        let secondSurvey = makeMidSurvey(path: "mid/second", showAfter: 20)
        let originalStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [firstSurvey, secondSurvey]
        )

        originalStudy.completeMidSurvey()

        let restoredStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [secondSurvey, firstSurvey],
            resetStoredState: false
        )
        defer { try? restoredStudy.reset() }

        XCTAssertEqual(
            restoredStudy.midStudySurveys.map(\.hasBeenCompleted),
            [false, true]
        )
        XCTAssertFalse(restoredStudy.hasCompletedMidSurvey)
        XCTAssertEqual(restoredStudy.surveyUrl(for: .mid)?.path, "/mid/second")
    }

    func testAddingExpirationPreservesExistingCompletion() {
        let studyIdentifier = UUID().uuidString
        let originalSurvey = makeMidSurvey(path: "mid/original", showAfter: 10)
        let originalStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [originalSurvey]
        )

        originalStudy.completeMidSurvey()

        let restoredStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [
                makeMidSurvey(
                    path: "mid/original",
                    showAfter: 10,
                    expiresAfter: 20
                )
            ],
            resetStoredState: false
        )
        defer { try? restoredStudy.reset() }

        XCTAssertTrue(restoredStudy.midStudySurveys[0].hasBeenCompleted)
        XCTAssertTrue(restoredStudy.hasCompletedMidSurvey)
        XCTAssertTrue(restoredStudy.hasResolvedMidStudySurveys)
        XCTAssertNil(restoredStudy.surveyUrl(for: .mid))
    }

    func testLegacyCompletedBooleanMigratesOnlyTheFirstConfiguredSurvey() {
        let studyIdentifier = UUID().uuidString
        let surveys = [
            makeMidSurvey(path: "mid/first", showAfter: 10),
            makeMidSurvey(path: "mid/second", showAfter: 20),
        ]
        let legacyStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: surveys
        )

        legacyStudy.store.update(Study.Keys.HasCompletedMidSurvey, value: true)

        XCTAssertEqual(
            legacyStudy.midStudySurveys.map(\.hasBeenCompleted),
            [true, false]
        )
        XCTAssertFalse(legacyStudy.hasCompletedMidSurvey)
        XCTAssertEqual(legacyStudy.surveyUrl(for: .mid)?.path, "/mid/second")

        // The new representation must remain authoritative after the lazy migration.
        legacyStudy.store.update(Study.Keys.HasCompletedMidSurvey, value: false)

        let restoredStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: surveys,
            resetStoredState: false
        )
        defer { try? restoredStudy.reset() }

        XCTAssertFalse(restoredStudy.hasCompletedMidSurvey)
        XCTAssertEqual(restoredStudy.surveyUrl(for: .mid)?.path, "/mid/second")
    }

    func testLegacyCompletedBooleanMigratesTheOriginalFirstEntryWhenEarlierSurveyIsAdded() {
        let studyIdentifier = UUID().uuidString
        let originalSurvey = makeMidSurvey(path: "mid/original", showAfter: 20)
        let legacyStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [originalSurvey]
        )

        legacyStudy.store.update(Study.Keys.HasCompletedMidSurvey, value: true)

        let restoredStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [
                originalSurvey,
                makeMidSurvey(path: "mid/new-earlier", showAfter: 10),
            ],
            resetStoredState: false
        )
        defer { try? restoredStudy.reset() }

        XCTAssertFalse(restoredStudy.hasCompletedMidSurvey)
        XCTAssertEqual(restoredStudy.surveyUrl(for: .mid)?.path, "/mid/new-earlier")
    }

    func testLegacyBooleanTracksOriginalFirstEntryRatherThanPresentationOrder() {
        let originalSurvey = makeMidSurvey(path: "mid/original", showAfter: 20)
        let earlierSurvey = makeMidSurvey(path: "mid/new-earlier", showAfter: 10)
        let study = createLongTermMidStudy(
            midStudySurveys: [originalSurvey, earlierSurvey]
        )
        defer { try? study.reset() }

        study.completeMidSurvey()

        XCTAssertEqual(
            study.store.get(Study.Keys.HasCompletedMidSurvey, type: Bool.self),
            false
        )

        study.completeMidSurvey()

        XCTAssertEqual(
            study.store.get(Study.Keys.HasCompletedMidSurvey, type: Bool.self),
            true
        )
    }

    func testExistingParticipantReconcilesNotificationIdentifiersForUpdatedConfiguration() {
        let studyIdentifier = UUID().uuidString
        let originalStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            duration: 10 * 24 * 60 * 60,
            midStudySurveys: [
                MidStudySurvey(
                    id: "original",
                    showAfter: 60 * 60,
                    url: URL(string: "https://example.com/mid/original")!
                )
            ]
        )
        let consentDate = Date()
        originalStudy.store.update(Study.Keys.UserConsentDate, value: consentDate)
        originalStudy.registerNotifications()

        let replacementSurvey = MidStudySurvey(
            id: "replacement",
            showAfter: 2 * 60 * 60,
            url: URL(string: "https://example.com/mid/replacement")!
        )
        let restoredStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            duration: 10 * 24 * 60 * 60,
            midStudySurveys: [replacementSurvey],
            resetStoredState: false
        )
        defer { try? restoredStudy.reset() }

        let registeredIdentifiers = Set(
            restoredStudy.registeredMidStudySurveyNotificationIdentifiers
        )

        XCTAssertEqual(
            registeredIdentifiers,
            Set([
                restoredStudy.midStudySurveyNotificationIdentifier(
                    for: replacementSurvey
                ),
                restoredStudy.midStudySurveyReminderNotificationIdentifier(
                    for: replacementSurvey
                ),
            ])
        )
        XCTAssertFalse(registeredIdentifiers.contains {
            $0.contains(originalStudy.midStudySurveys[0].completionIdentifier)
        })
    }

    func testExactDuplicateMidSurveysAreCompletedAsOneLogicalSurvey() {
        let duplicate = makeMidSurvey(path: "mid/repeated", showAfter: 10)
        let study = createLongTermMidStudy(midStudySurveys: [duplicate, duplicate])
        defer { try? study.reset() }

        study.completeMidSurvey()

        XCTAssertTrue(study.hasCompletedMidSurvey)
        XCTAssertTrue(
            study.midStudySurveys.allSatisfy(\.hasBeenCompleted)
        )
        XCTAssertNil(study.surveyUrl(for: .mid))
    }

    func testResetClearsReportedMidSurveyCompletionState() throws {
        let study = createLongTermMidStudy(
            midStudySurveys: [
                makeMidSurvey(path: "mid/first", showAfter: 10)
            ]
        )

        study.completeMidSurvey()
        XCTAssertTrue(study.midStudySurveys[0].hasBeenCompleted)

        try study.reset()

        XCTAssertFalse(study.midStudySurveys[0].hasBeenCompleted)
    }

    func testSameMidSurveyUrlAtDifferentTimesCreatesDistinctSurveys() {
        let url = URL(string: "https://example.com/mid/repeated")!
        let study = createLongTermMidStudy(
            midStudySurveys: [
                MidStudySurvey(showAfter: 10, url: url),
                MidStudySurvey(showAfter: 20, url: url),
            ]
        )
        defer { try? study.reset() }

        study.completeMidSurvey()

        XCTAssertFalse(study.hasCompletedMidSurvey)
        XCTAssertNotNil(study.surveyUrl(for: .mid))

        study.completeMidSurvey()

        XCTAssertTrue(study.hasCompletedMidSurvey)
        XCTAssertNil(study.surveyUrl(for: .mid))
    }

    func testCompletingCapturedMidSurveyTwiceDoesNotAdvanceAnotherSurvey() {
        let firstSurvey = makeMidSurvey(path: "mid/first", showAfter: 10)
        let secondSurvey = makeMidSurvey(path: "mid/second", showAfter: 20)
        let study = createLongTermMidStudy(
            midStudySurveys: [firstSurvey, secondSurvey]
        )
        defer { try? study.reset() }

        study.completeMidSurvey(identifier: firstSurvey.completionIdentifier)
        study.completeMidSurvey(identifier: firstSurvey.completionIdentifier)

        XCTAssertFalse(study.hasCompletedMidSurvey)
        XCTAssertEqual(study.surveyUrl(for: .mid)?.path, "/mid/second")
    }

    func testEachMidSurveyHasUniqueNotificationIdentifiers() {
        let firstSurvey = makeMidSurvey(path: "mid/first", showAfter: 10)
        let secondSurvey = makeMidSurvey(path: "mid/second", showAfter: 20)
        let study = createLongTermMidStudy(
            midStudySurveys: [firstSurvey, secondSurvey]
        )
        defer { try? study.reset() }

        let firstNotification = study.midStudySurveyNotificationIdentifier(for: firstSurvey)
        let secondNotification = study.midStudySurveyNotificationIdentifier(for: secondSurvey)
        let firstReminder = study.midStudySurveyReminderNotificationIdentifier(for: firstSurvey)

        XCTAssertNotEqual(firstNotification, secondNotification)
        XCTAssertNotEqual(firstNotification, firstReminder)
    }

    func testMidSurveyReminderIsNotScheduledAtOrAfterExpiration() {
        let reminderDelay: TimeInterval = 3 * 24 * 60 * 60
        let survey = MidStudySurvey(
            id: "expiring",
            showAfter: 60 * 60,
            url: URL(string: "https://example.com/mid/expiring")!,
            expiresAfter: reminderDelay
        )
        let study = createLongTermMidStudy(
            duration: 10 * 24 * 60 * 60,
            midStudySurveys: [survey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        study.registerNotifications()

        XCTAssertEqual(
            study.registeredMidStudySurveyNotificationIdentifiers,
            [study.midStudySurveyNotificationIdentifier(for: survey)]
        )
    }

    func testReconciliationClearsTrackedNotificationsAfterExpiration() {
        let survey = makeMidSurvey(
            path: "mid/expiring",
            showAfter: 60 * 60,
            expiresAfter: 2 * 24 * 60 * 60
        )
        let study = createLongTermMidStudy(
            duration: 10 * 24 * 60 * 60,
            midStudySurveys: [survey]
        )
        defer { try? study.reset() }
        let dateGenerator = TimeTraveler()

        giveConsent(to: study, using: dateGenerator)
        study.registerNotifications()
        XCTAssertFalse(study.registeredMidStudySurveyNotificationIdentifiers.isEmpty)

        dateGenerator.travel(by: 60 * 60 + 2 * 24 * 60 * 60)
        study.registerNotifications()

        XCTAssertTrue(study.registeredMidStudySurveyNotificationIdentifiers.isEmpty)
    }

    func testNotificationIdentifiersCannotCollideThroughDelimiters() {
        let firstSurvey = MidStudySurvey(
            id: "c",
            showAfter: 10,
            url: URL(string: "https://example.com/mid/first")!
        )
        let secondSurvey = MidStudySurvey(
            id: "b|c",
            showAfter: 10,
            url: URL(string: "https://example.com/mid/second")!
        )
        let firstStudy = createLongTermMidStudy(
            studyIdentifier: "a|b",
            midStudySurveys: [firstSurvey]
        )
        let secondStudy = createLongTermMidStudy(
            studyIdentifier: "a",
            midStudySurveys: [secondSurvey]
        )
        defer {
            try? firstStudy.reset()
            try? secondStudy.reset()
        }

        XCTAssertNotEqual(
            firstStudy.midStudySurveyNotificationIdentifier(for: firstSurvey),
            secondStudy.midStudySurveyNotificationIdentifier(for: secondSurvey)
        )
    }

    func testCompletingStudyClearsTrackedMidSurveyNotifications() {
        let study = createLongTermMidStudy(
            duration: 10 * 24 * 60 * 60,
            midStudySurveys: [
                makeMidSurvey(path: "mid/first", showAfter: 60 * 60)
            ]
        )
        defer { try? study.reset() }
        study.store.update(Study.Keys.UserConsentDate, value: Date())
        study.registerNotifications()

        XCTAssertFalse(study.registeredMidStudySurveyNotificationIdentifiers.isEmpty)

        study.setCompleted()

        XCTAssertTrue(study.registeredMidStudySurveyNotificationIdentifiers.isEmpty)
    }

    func testRestoringCompletedStudyDoesNotRescheduleMidSurveyNotifications() {
        let studyIdentifier = UUID().uuidString
        let originalStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: [
                makeMidSurvey(path: "mid/first", showAfter: 60 * 60)
            ]
        )
        originalStudy.store.update(Study.Keys.UserConsentDate, value: Date())
        originalStudy.store.update(Study.Keys.CompletionDate, value: Date())
        originalStudy.store.update(
            Study.Keys.RegisteredMidStudySurveyNotificationIdentifiers,
            value: ["stale-mid-survey-notification"]
        )

        let restoredStudy = createLongTermMidStudy(
            studyIdentifier: studyIdentifier,
            midStudySurveys: originalStudy.midStudySurveys,
            resetStoredState: false
        )
        defer { try? restoredStudy.reset() }

        XCTAssertTrue(restoredStudy.registeredMidStudySurveyNotificationIdentifiers.isEmpty)
    }
    
    func testStudyAdditionalQueryItems() {
        let study = createLongTermStudy()
        
        study.additionalQueryItems = { _ in
            return [URLQueryItem(name: "version", value: "1.0")]
        }
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("version=1.0"))
    }
    
    func testStudyUserIdentifierGeneration() {
        let study = createLongTermStudy()
        
        let userIdentifier = study.userIdentifier
        
        XCTAssertFalse(userIdentifier.isEmpty)
    }
    
    func testStudyJSONFileHandling() {
        let study = createLongTermStudy()
        
        try? study.reset()
        study.saveUserConsentHasBeenGiven(completion: {})
        
        let initialJSONFile = study.JSONFile
        XCTAssertTrue(initialJSONFile.isEmpty)
        
        let newObjects: [[String: JSONConvertible]] = [
            ["key1": "value1", "timestamp": 123_456_789],
            ["key2": "value2", "timestamp": 123_456_790],
        ]
        
        study.appendNewJSONObjects(newObjects: newObjects)
        
        let updatedJSONFile = study.JSONFile
        XCTAssertEqual(updatedJSONFile.count, 2)
    }
    
    func testStudyUploadDateHandling() {
        let study = createLongTermStudy()
        
        try? study.reset()
        
        XCTAssertNil(study.lastSuccessfulUploadDate)
        
        let testDate = Date()
        study.updateUploadDate(newDate: testDate)
        
        XCTAssertNotNil(study.lastSuccessfulUploadDate)
        XCTAssertEqual(
            study.lastSuccessfulUploadDate!.timeIntervalSince1970, testDate.timeIntervalSince1970,
            accuracy: 1.0)
    }
    
    func testFinishedConclusionSurveyOrNotNeeded() {
        
        let study1 = createLongTermStudy(concludingSurvey: nil)
        
        // Concluding survey not needed
        XCTAssertTrue(study1.finishedConclusionSurveyOrNotNeeded)
        
        let study2 = createLongTermStudy(concludingSurvey: URL(string: "https://example.org")!)
        
        // Concluding survey needed but not finished
        XCTAssertFalse(study2.finishedConclusionSurveyOrNotNeeded)
        
        study2.completeTerminationSurvey()
        
        // Concluding survey needed and now finished
        XCTAssertTrue(study2.finishedConclusionSurveyOrNotNeeded)
        
    }
    
    func testIsActiveLongTermWithConclusionSurveyRegularFlow() {
        
        let dateGenerator = TimeTraveler()
        let study = createLongTermStudy()
        study.dateGenerator = dateGenerator
        
        XCTAssertFalse(study.isActive)
        
        study.saveUserConsentHasBeenGiven(completion: {})
        
        XCTAssertTrue(study.isActive)
        
        dateGenerator.travel(by: 20)
        
        study.completeTerminationSurvey()
        
        XCTAssertFalse(study.isActive)
        
    }
    
    func testIsActiveLongTermWithConclusionEarlyTerminate() {
        
        let dateGenerator = TimeTraveler()
        let study = createLongTermStudy(duration: 10)
        study.dateGenerator = dateGenerator
        
        XCTAssertFalse(study.isActive)
        
        study.saveUserConsentHasBeenGiven(completion: {})
        
        dateGenerator.travel(by: 5)
        XCTAssertTrue(study.isActive)
        
        dateGenerator.travel(by: 20)
        
        // Should be true as the user still needs to do the termination survey
        XCTAssertTrue(study.isActive)
        
        study.terminateParticipationImmediately()
        
        XCTAssertFalse(study.isActive)
        
    }

    func testEarlyTerminateAppendsTerminationDataPoint() {
        let dateGenerator = TimeTraveler()
        let study = createLongTermStudy(duration: 10)
        study.dateGenerator = dateGenerator

        study.saveUserConsentHasBeenGiven(completion: {})

        dateGenerator.travel(by: 5)
        study.terminateParticipationImmediately()

        let terminationDataPoint = study.JSONFile.last
        XCTAssertEqual(terminationDataPoint?["terminationReason"] as? String, "terminatedByUser")

        guard let timestamp = terminationDataPoint?["timestamp"] as? Double,
              let terminationDate = study.terminationBeforeCompletionDate else {
            XCTFail("Expected a termination timestamp and stored termination date")
            return
        }

        XCTAssertEqual(timestamp, terminationDate.timeIntervalSince1970, accuracy: 0.001)
    }
    
    // MARK: - Long Term without Conclusion
    
    func testIsActiveLongTermWithoutConclusionSurveyRegularFlow() {
        
        let dateGenerator = TimeTraveler()
        let study = createLongTermStudy(concludingSurvey: nil, duration: 10)
        study.dateGenerator = dateGenerator
        
        XCTAssertFalse(study.isActive)
        
        study.saveUserConsentHasBeenGiven(completion: {})
        
        XCTAssertTrue(study.isActive)
        
        dateGenerator.travel(by: 5)
        
        XCTAssertTrue(study.isActive)
        
        dateGenerator.travel(by: 6)
        
        XCTAssertFalse(study.isActive)
        
    }
    
    // MARK: - Test helpers
    
    private let uploadConfiguration = UploadConfiguration(
        serverURL: URL(string: "https://example.com/upload")!,
        uploadFrequency: 60,
        apiKey: "test"
    )
    
    private func createLongTermMidStudy(
        studyIdentifier: String = UUID().uuidString,
        introductorySurvey: URL? = URL(string: "https://example.com/intro")!,
        concludingSurvey: URL? = URL(string: "https://example.com/conclusion")!,
        duration: TimeInterval = 10,
        midStudySurveys: [MidStudySurvey]? = nil,
        additionalQueryItems: @escaping (SurveyType) -> [URLQueryItem] = { _ in [] },
        resetStoredState: Bool = true
    ) -> LongTermWithMidSurveyStudy {
        let configuredMidStudySurveys = midStudySurveys ?? [
            makeMidSurvey(path: "mid", showAfter: 50 * 60)
        ]
        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: studyIdentifier,
            studyInformation: makeStudyInformation(),
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurvey!,
            midStudySurveys: configuredMidStudySurveys,
            concludingSurveyURL: concludingSurvey!,
            additionalQueryItems: additionalQueryItems
        )
        
        if resetStoredState {
            try? study.reset()
        }
        
        return study
        
    }

    private func makeMidSurvey(
        path: String,
        showAfter: TimeInterval,
        expiresAfter: TimeInterval? = nil
    ) -> MidStudySurvey {
        MidStudySurvey(
            showAfter: showAfter,
            url: URL(string: "https://example.com/\(path)")!,
            expiresAfter: expiresAfter
        )
    }

    private func makeStudyInformation() -> StudyInformation {
        StudyInformation(
            title: "Test Study",
            subtitle: "Test Subtitle",
            contactEmail: "test@example.com",
            image: nil
        )
    }

    private func giveConsent(
        to study: LongTermWithMidSurveyStudy,
        using dateGenerator: TimeTraveler
    ) {
        study.dateGenerator = dateGenerator
        study.store.update(
            Study.Keys.UserConsentDate,
            value: dateGenerator.generate()
        )
    }
    
    private func createLongTermStudy(
        introductorySurvey: URL? = URL(string: "https://example.com/intro")!,
        concludingSurvey: URL? = URL(string: "https://example.com/conclusion")!,
        duration: TimeInterval = 10
    ) -> LongTermStudy {
        
        let study = LongTermStudy(
            studyIdentifier: UUID().uuidString,
            studyInformation: .init(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: uploadConfiguration,
            duration: duration,
            introductorySurveyURL: introductorySurvey,
            concludingSurveyURL: concludingSurvey
        )
        
        try? study.reset()
        
        return study
        
    }
    
}

private final class CountingDateGenerator: DateGenerator {

    init(date: Date) {
        self.date = date
    }

    private let date: Date
    private(set) var generationCount = 0

    func generate() -> Date {
        generationCount += 1
        return date
    }

}
