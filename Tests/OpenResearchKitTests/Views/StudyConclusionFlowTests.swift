//
//  StudyConclusionFlowTests.swift
//  OpenResearchKit
//

import Foundation
import SwiftUI
import Testing
import UIKit

@testable import OpenResearchKit

@Suite("Study conclusion flow", .serialized)
struct StudyConclusionFlowTests {

    @Test(
        "The content gives way to the conclusion survey when the study period ends",
        .timeLimit(.minutes(1))
    )
    @MainActor
    func contentGivesWayAtStudyEnd() async {
        let recorder = BannerRenderRecorder(marker: "running")
        let study = makeStudy(duration: 1)
        defer { try? study.reset() }
        study.store.update(Study.Keys.UserConsentDate, value: Date())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: StudyConclusionFlow(study: study) {
            BannerRenderProbe(identifier: recorder.marker, recorder: recorder)
        })
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        await recorder.waitUntilRendered("running")
        #expect(study.pendingConclusionStep == nil)

        await recorder.waitUntilRendered("running-removed")
        #expect(study.pendingConclusionStep == .survey)
    }

    private func makeStudy(duration: TimeInterval) -> LongTermStudy {
        let study = ConclusionFlowTestStudy(
            studyIdentifier: "StudyConclusionFlowTests-\(UUID().uuidString)",
            studyInformation: StudyInformation(
                title: "Test Study",
                subtitle: "Test Subtitle",
                contactEmail: "test@example.com",
                image: nil
            ),
            uploadConfiguration: .dummy,
            duration: duration,
            introductorySurveyURL: URL(string: "https://example.com/intro")!,
            concludingSurveyURL: URL(string: "https://example.com/conclusion")!
        )
        try? study.reset()
        return study
    }

}

private final class ConclusionFlowTestStudy: LongTermStudy {

    override var requiresCompletionAcknowledgement: Bool {
        true
    }

    override func shouldHaveNotifications() -> Bool {
        false
    }

}
