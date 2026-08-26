//
//  AbsoluteStudyScheduleTests.swift
//
//
//  Created by Lennart Fischer on 26.08.26.
//

import Foundation
import Testing

@testable import OpenResearchKit

@Suite("Fixed-date study schedules")
struct FixedDateStudyScheduleTests {

    @Test("The study end stays fixed when consent happens after initialization")
    func studyEndStaysFixedAfterConsent() throws {
        let studyEnd = Date(timeIntervalSince1970: 2_000_000_000)
        let consentDate = studyEnd.addingTimeInterval(-100)
        let study = makeStudy(studyEnd: studyEnd, midStudySurveys: [])
        defer { try? study.reset() }

        study.store.update(
            Study.Keys.UserConsentDate,
            value: consentDate
        )

        #expect(study.intendedStudyEndDate == studyEnd)
        #expect(study.actualStudyEndDate == studyEnd)
    }

    @Test("Fixed mid-study survey dates stay fixed after consent")
    func midSurveyDatesStayFixedAfterConsent() throws {
        let consentDate = Date(timeIntervalSince1970: 2_000_000_000)
        let firstSurveyDate = consentDate.addingTimeInterval(120)
        let secondSurveyDate = consentDate.addingTimeInterval(360)
        let study = makeStudy(
            studyEnd: consentDate.addingTimeInterval(480),
            midStudySurveys: makeFixedSurveys(
                at: [firstSurveyDate, secondSurveyDate]
            )
        )
        defer { try? study.reset() }

        study.store.update(
            Study.Keys.UserConsentDate,
            value: consentDate
        )

        let resolvedDates = study.midStudySurveys.compactMap {
            study.midStudySurveyAvailabilityDate(for: $0)
        }
        #expect(resolvedDates == [firstSurveyDate, secondSurveyDate])
    }

    @Test("Mid-study survey reminders do not extend past the fixed study end")
    func midSurveyRemindersStopAtStudyEnd() throws {
        let consentDate = Date.now
        let firstSurveyDate = consentDate.addingTimeInterval(120)
        let secondSurveyDate = consentDate.addingTimeInterval(360)
        let study = makeStudy(
            studyEnd: consentDate.addingTimeInterval(480),
            midStudySurveys: makeFixedSurveys(
                at: [firstSurveyDate, secondSurveyDate]
            )
        )
        defer { try? study.reset() }
        study.dateGenerator = FixedDateGenerator(date: consentDate)
        study.store.update(
            Study.Keys.UserConsentDate,
            value: consentDate
        )

        study.registerNotifications()

        let expectedIdentifiers = Set(
            study.midStudySurveys.map {
                study.midStudySurveyNotificationIdentifier(for: $0)
            }
        )
        #expect(
            Set(study.registeredMidStudySurveyNotificationIdentifiers)
                == expectedIdentifiers
        )
    }

    @Test("Consent-relative and fixed-date surveys share one ordered collection")
    func scheduleKindsShareOneCollection() throws {
        let consentDate = Date(timeIntervalSince1970: 2_000_000_000)
        let fixedDate = consentDate.addingTimeInterval(60)
        let relativeDate = consentDate.addingTimeInterval(120)
        let study = makeStudy(
            studyEnd: consentDate.addingTimeInterval(480),
            midStudySurveys: [
                MidStudySurvey(
                    id: "relative",
                    schedule: .relativeToConsent(
                        availableAfter: 120,
                        expiresAfter: nil
                    ),
                    url: URL(string: "https://example.com/mid/relative")!
                ),
                MidStudySurvey(
                    id: "fixed",
                    schedule: .fixedDates(
                        availableAt: fixedDate,
                        expiresAfter: nil
                    ),
                    url: URL(string: "https://example.com/mid/fixed")!
                )
            ]
        )
        defer { try? study.reset() }
        study.store.update(
            Study.Keys.UserConsentDate,
            value: consentDate
        )

        #expect(study.scheduledMidStudySurveys.map(\.id) == ["fixed", "relative"])
        #expect(
            study.scheduledMidStudySurveys.compactMap {
                study.midStudySurveyAvailabilityDate(for: $0)
            } == [fixedDate, relativeDate]
        )
    }

    private func makeStudy(
        studyEnd: Date,
        midStudySurveys: [MidStudySurvey]
    ) -> LongTermWithMidSurveyStudy {
        LongTermWithMidSurveyStudy(
            studyIdentifier: UUID().uuidString,
            studyInformation: StudyInformation(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                serverURL: URL(string: "https://example.com/upload")!,
                uploadFrequency: 24 * 60 * 60,
                apiKey: "test"
            ),
            studyEndDate: studyEnd,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            midStudySurveys: midStudySurveys,
            concludingSurveyURL: URL(string: "https://example.com/final")!
        )
    }

    private func makeFixedSurveys(at dates: [Date]) -> [MidStudySurvey] {
        dates.enumerated().map { index, date in
            MidStudySurvey(
                id: "survey-\(index)",
                schedule: .fixedDates(
                    availableAt: date,
                    expiresAfter: nil
                ),
                url: URL(string: "https://example.com/mid/\(index)")!
            )
        }
    }
}

private struct FixedDateGenerator: DateGenerator {
    let date: Date

    func generate() -> Date {
        date
    }
}
