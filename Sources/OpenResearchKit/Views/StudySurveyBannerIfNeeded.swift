//
//  StudySurveyBannerIfNeeded.swift
//
//
//  Created by Lennart Fischer on 26.08.26.
//

import SwiftUI

/// Shows the banner of the survey that is due now, or nothing when no survey is due.
///
/// The banner refreshes when the study changes, when the app becomes active, and when a survey
/// becomes available or expires while it is visible.
public struct StudySurveyBannerIfNeeded<Content: View>: View {

    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var study: Study

    private let content: (AnyView) -> Content

    @State private var evaluationDate: Date

    public init(
        study: Study,
        @ViewBuilder content: @escaping (AnyView) -> Content
    ) {
        self.study = study
        self.content = content
        self._evaluationDate = State(
            initialValue: study.dateGenerator.generate()
        )
    }

    public var body: some View {
        ZStack {
            banner(for: study.surveyBanner(at: evaluationDate))
        }
        .onAppear(perform: refresh)
        .onChange(of: study.studyIdentifier) { _ in
            refresh()
        }
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .active else {
                return
            }

            refresh()
        }
        .task(id: study.nextSurveyBannerChangeDate(after: evaluationDate)) {
            await refreshAtNextChange()
        }
    }

    @ViewBuilder
    private func banner(for surveyBanner: StudySurveyBanner?) -> some View {
        switch surveyBanner {
        case .mid(let survey):
            if let midSurveyStudy = study as? (any HasMidSurvey) {
                content(midSurveyStudy.midSurveyBannerView(for: survey))
            }
        case .completion:
            if let terminationSurveyStudy = study as? (any HasTerminationSurvey) {
                content(terminationSurveyStudy.terminationBannerView)
            }
        case nil:
            EmptyView()
        }
    }

    private func refresh() {
        evaluationDate = study.dateGenerator.generate()
    }

    /// Refreshes when a survey becomes available or expires. Cancelled when the change date changes
    /// or the view disappears.
    private func refreshAtNextChange() async {
        guard let changeDate = study.nextSurveyBannerChangeDate(after: evaluationDate) else {
            return
        }

        let delay = max(changeDate.timeIntervalSince(study.dateGenerator.generate()), 0)

        // A short margin makes sure the change date has passed when the state is read again.
        try? await Task.sleep(nanoseconds: UInt64((delay + 0.5) * 1_000_000_000))

        guard !Task.isCancelled else {
            return
        }

        refresh()
    }

}

#if DEBUG

#Preview("Mid-study survey") {
    StudySurveyBannerIfNeeded(
        study: makeSurveyBannerPreviewStudy(showing: .mid)
    ) { $0 }
    .padding()
}

#Preview("Completion survey") {
    StudySurveyBannerIfNeeded(
        study: makeSurveyBannerPreviewStudy(showing: .completion)
    ) { $0 }
    .padding()
}

private func makeSurveyBannerPreviewStudy(
    showing surveyType: SurveyType
) -> LongTermWithMidSurveyStudy {
    let study = LongTermWithMidSurveyStudy(
        studyIdentifier: "StudySurveyBannerIfNeededPreview-\(surveyType)-\(UUID().uuidString)",
        studyInformation: StudyInformation(
            title: "Example Research Project",
            subtitle: "Help us understand how intentional app use changes over time.",
            contactEmail: "research@example.com",
            image: nil
        ),
        uploadConfiguration: UploadConfiguration(
            serverURL: URL(string: "https://example.com/upload")!,
            uploadFrequency: 86_400,
            apiKey: "preview"
        ),
        duration: surveyType == .completion ? 10 : 100,
        introductorySurveyURL: URL(string: "https://example.com/intro")!,
        midStudySurveys: [
            MidStudySurvey(
                id: "preview-mid-survey",
                showAfter: 10,
                url: URL(string: "https://example.com/mid")!
            )
        ],
        concludingSurveyURL: URL(string: "https://example.com/completion")!
    )

    study.store.update(
        Study.Keys.UserConsentDate,
        value: Date().addingTimeInterval(-20)
    )

    return study
}

#endif
