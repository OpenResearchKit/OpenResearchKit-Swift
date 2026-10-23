//
//  StudySurveyBannerTests.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.10.26.
//

import Foundation
import Testing

@testable import OpenResearchKit

@Suite("Study survey banner evaluation", .serialized)
struct StudySurveyBannerTests {

    // MARK: - Change Dates -

    @Test("The next change is the earliest availability, expiry, or study end")
    func nextChangeDate() {
        let study = makeStudy(
            duration: 100,
            midStudySurveys: [
                makeMidSurvey(id: "first", showAfter: 10, expiresAfter: 5),
                makeMidSurvey(id: "second", showAfter: 50)
            ]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        let consentDate = dateGenerator.generate()

        #expect(study.nextSurveyBannerChangeDate(after: consentDate) == consentDate.addingTimeInterval(10))
        #expect(study.nextSurveyBannerChangeDate(after: consentDate.addingTimeInterval(10)) == consentDate.addingTimeInterval(15))
        #expect(study.nextSurveyBannerChangeDate(after: consentDate.addingTimeInterval(20)) == consentDate.addingTimeInterval(50))
        #expect(study.nextSurveyBannerChangeDate(after: consentDate.addingTimeInterval(60)) == consentDate.addingTimeInterval(100))
        #expect(study.nextSurveyBannerChangeDate(after: consentDate.addingTimeInterval(100)) == nil)
    }

    @Test("A study without consent has no scheduled change")
    func noChangeWithoutConsent() {
        let study = makeStudy(midStudySurveys: [makeMidSurvey(id: "first", showAfter: 10)])
        defer { try? study.reset() }

        #expect(study.nextSurveyBannerChangeDate(after: Date()) == nil)
    }

    @Test("Completed mid-study surveys are not scheduled")
    func completedSurveysAreNotScheduled() {
        let study = makeStudy(
            duration: 100,
            midStudySurveys: [makeMidSurvey(id: "first", showAfter: 10)]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        let consentDate = dateGenerator.generate()
        dateGenerator.travel(by: 10)
        study.completeMidSurvey()

        #expect(study.nextSurveyBannerChangeDate(after: consentDate) == consentDate.addingTimeInterval(100))
    }

    @Test("No mid-study survey is due after the conclusion survey was completed")
    func noSurveyAfterConclusionSurvey() {
        let study = makeStudy(
            duration: 30,
            midStudySurveys: [makeMidSurvey(id: "mid", showAfter: 10)]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        dateGenerator.travel(by: 30)

        #expect(study.surveyBanner(at: dateGenerator.generate()) == .completion)

        study.completeTerminationSurvey()

        #expect(study.surveyBanner(at: dateGenerator.generate()) == nil)
    }

    @Test("No conclusion survey is due without a conclusion survey URL or after completion")
    func noConclusionBannerWithoutSurveyOrAfterCompletion() {
        let withoutSurvey = LongTermStudy(
            studyIdentifier: "StudySurveyBannerTests-\(UUID().uuidString)",
            studyInformation: StudyInformation(title: "T", subtitle: "S", contactEmail: "test@example.com", image: nil),
            uploadConfiguration: .dummy,
            duration: 10,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            concludingSurveyURL: nil
        )
        let completed = makeStudy(duration: 10, midStudySurveys: [])
        defer {
            try? withoutSurvey.reset()
            try? completed.reset()
        }
        let first = giveConsent(to: withoutSurvey)
        let second = giveConsent(to: completed)
        first.travel(by: 11)
        second.travel(by: 11)

        #expect(withoutSurvey.surveyBanner(at: first.generate()) == nil)
        #expect(withoutSurvey.nextSurveyBannerChangeDate(after: first.generate().addingTimeInterval(-20)) == nil)

        completed.setCompleted()

        #expect(completed.surveyBanner(at: second.generate()) == nil)
    }

    @Test("Banners compare by survey identity")
    func bannerEquality() {
        let first = makeMidSurvey(id: "first", showAfter: 10)
        let second = makeMidSurvey(id: "second", showAfter: 10)

        #expect(StudySurveyBanner.mid(first) == .mid(first))
        #expect(StudySurveyBanner.mid(first) != .mid(second))
        #expect(StudySurveyBanner.mid(first) != .completion)
    }

    // MARK: - Helpers -

    private func makeStudy(
        duration: TimeInterval = 100,
        midStudySurveys: [MidStudySurvey]
    ) -> LongTermWithMidSurveyStudy {
        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: "StudySurveyBannerTests-\(UUID().uuidString)",
            studyInformation: StudyInformation(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: .dummy,
            duration: duration,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            midStudySurveys: midStudySurveys,
            concludingSurveyURL: URL(string: "https://example.com/completion")!
        )
        try? study.reset()
        return study
    }

    private func makeMidSurvey(
        id: String,
        showAfter: TimeInterval,
        expiresAfter: TimeInterval? = nil
    ) -> MidStudySurvey {
        MidStudySurvey(
            id: id,
            showAfter: showAfter,
            url: URL(string: "https://example.com/mid/\(id)")!,
            expiresAfter: expiresAfter
        )
    }

    private func giveConsent(to study: Study) -> TimeTraveler {
        let dateGenerator = TimeTraveler()
        study.dateGenerator = dateGenerator
        study.store.update(Study.Keys.UserConsentDate, value: dateGenerator.generate())
        return dateGenerator
    }

}
