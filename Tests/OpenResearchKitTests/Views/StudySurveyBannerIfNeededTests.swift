//
//  StudySurveyBannerIfNeededTests.swift
//  OpenResearchKit
//

import Foundation
import SwiftUI
import Testing
import UIKit

@testable import OpenResearchKit

@Suite("Study survey banner", .serialized)
struct StudySurveyBannerIfNeededTests {

    @Test(
        "A due survey appears when the overview appears",
        .timeLimit(.minutes(1))
    )
    @MainActor
    func dueSurveyAppearsWhenOverviewAppears() async {
        let recorder = BannerRenderRecorder(marker: "due")
        let study = makeStudy(
            midStudySurveys: [makeMidSurvey(id: "first", showAfter: 10)]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        dateGenerator.travel(by: 9)
        let view = StudySurveyBannerIfNeeded(study: study) { banner in
            banner.background {
                BannerRenderProbe(
                    identifier: recorder.marker,
                    recorder: recorder
                )
            }
        }
        dateGenerator.travel(by: 1)
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        await recorder.waitUntilRendered("due")
    }

    @Test(
        "Completing a survey refreshes the visible banner",
        .timeLimit(.minutes(1))
    )
    @MainActor
    func completionRefreshesVisibleBanner() async {
        let recorder = BannerRenderRecorder(marker: "initial")
        let study = makeStudy(
            midStudySurveys: [
                makeMidSurvey(id: "first", showAfter: 10),
                makeMidSurvey(id: "second", showAfter: 20)
            ]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        dateGenerator.travel(by: 25)
        let view = StudySurveyBannerIfNeeded(study: study) { banner in
            banner.background {
                BannerRenderProbe(
                    identifier: recorder.marker,
                    recorder: recorder
                )
            }
        }
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        await recorder.waitUntilRendered("initial")

        recorder.marker = "after-completion"
        study.completeMidSurvey()

        await recorder.waitUntilRendered("after-completion")
        #expect(study.midStudySurveyToDisplay?.id == "second")
    }

    @Test("A presented mid-study survey keeps its selected identity")
    func presentedMidStudySurveyKeepsSelectedIdentity() throws {
        let study = makeStudy(
            midStudySurveys: [
                makeMidSurvey(id: "first", showAfter: 10),
                makeMidSurvey(id: "second", showAfter: 20)
            ]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        dateGenerator.travel(by: 25)

        let selectedSurvey = try #require(study.midStudySurveyToDisplay)
        let surveyView = SurveyWebView(
            study: study,
            midStudySurvey: selectedSurvey
        )

        study.completeMidSurvey()

        #expect(study.midStudySurveyToDisplay?.id == "second")
        #expect(surveyView.midStudySurveyIdentifier == "first")
        #expect(surveyView.surveyURL?.path == "/mid/first")
    }

    @Test("The completion survey has priority after the study ends")
    func completionSurveyHasPriority() throws {
        let study = makeStudy(
            duration: 30,
            midStudySurveys: [makeMidSurvey(id: "mid", showAfter: 10)]
        )
        defer { try? study.reset() }
        let dateGenerator = giveConsent(to: study)
        dateGenerator.travel(by: 30)

        let surveyBanner = try #require(
            study.surveyBanner(at: dateGenerator.generate())
        )

        guard case .completion = surveyBanner else {
            Issue.record("Expected the completion survey banner")
            return
        }
    }

    @Test("Only an introductory banner can dismiss the study")
    func activeSurveyBannersCannotDismissStudy() {
        #expect(SurveyType.introductory.canDismissStudyFromBanner)
        #expect(!SurveyType.mid.canDismissStudyFromBanner)
        #expect(!SurveyType.completion.canDismissStudyFromBanner)
    }

    private func makeStudy(
        duration: TimeInterval = 100,
        midStudySurveys: [MidStudySurvey]
    ) -> LongTermWithMidSurveyStudy {
        let study = LongTermWithMidSurveyStudy(
            studyIdentifier: "StudySurveyBannerIfNeededTests-\(UUID().uuidString)",
            studyInformation: StudyInformation(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: UploadConfiguration(
                serverURL: URL(string: "https://example.com/upload")!,
                uploadFrequency: 60,
                apiKey: "test"
            ),
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
        showAfter: TimeInterval
    ) -> MidStudySurvey {
        MidStudySurvey(
            id: id,
            showAfter: showAfter,
            url: URL(string: "https://example.com/mid/\(id)")!
        )
    }

    private func giveConsent(
        to study: Study
    ) -> TimeTraveler {
        let dateGenerator = TimeTraveler()
        study.dateGenerator = dateGenerator
        study.store.update(
            Study.Keys.UserConsentDate,
            value: dateGenerator.generate()
        )
        return dateGenerator
    }

}

@MainActor
private final class BannerRenderRecorder {

    var marker: String

    private var renderedIdentifiers: Set<String> = []
    private let events: AsyncStream<String>
    private let eventContinuation: AsyncStream<String>.Continuation

    init(marker: String) {
        self.marker = marker
        (self.events, self.eventContinuation) = AsyncStream.makeStream()
    }

    func record(_ identifier: String) {
        renderedIdentifiers.insert(identifier)
        eventContinuation.yield(identifier)
    }

    func waitUntilRendered(_ expectedIdentifier: String) async {
        guard !renderedIdentifiers.contains(expectedIdentifier) else {
            return
        }

        for await identifier in events where identifier == expectedIdentifier {
            return
        }
    }

}

private struct BannerRenderProbe: UIViewRepresentable {

    let identifier: String
    let recorder: BannerRenderRecorder

    func makeUIView(context: Context) -> UIView {
        recorder.record(identifier)
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        recorder.record(identifier)
    }

}
