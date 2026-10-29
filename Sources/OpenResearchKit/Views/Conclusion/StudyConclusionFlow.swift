//
//  StudyConclusionFlow.swift
//  OpenResearchKit
//

import SwiftUI

/// Shows your content while the study runs, and the conclusion steps once the study period has ended.
///
/// For a study that requires a completion acknowledgement, the flow replaces `content` with
/// ``StudyConclusionSurveyView`` while the conclusion survey is pending, and with the conclusion and
/// ``StudyConclusionFinishButton`` once the participant has to confirm the end of their participation.
/// It switches at the end of the study period without any change to the study.
///
/// The flow adds no background, so it fits into a screen of your own, for example inside a `NavigationStack`.
public struct StudyConclusionFlow<Content: View>: View {

    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var study: LongTermStudy
    private let onFinish: () -> Void
    private let content: () -> Content

    @State private var evaluationDate: Date

    /// - Parameters:
    ///   - onFinish: Called after the participant finished their participation.
    ///   - content: Shown while no conclusion step is pending.
    public init(
        study: LongTermStudy,
        onFinish: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.study = study
        self.onFinish = onFinish
        self.content = content
        self._evaluationDate = State(initialValue: study.dateGenerator.generate())
    }

    public var body: some View {
        ZStack {
            switch study.pendingConclusionStep(at: evaluationDate) {
            case .survey:
                StudyConclusionSurveyView(study: study)
            case .acknowledgement:
                StudyConclusionView(study: study, showsBackground: false, onFinish: onFinish)
                    // The conclusion brings its own large header.
                    .navigationBarTitleDisplayMode(.inline)
            case nil:
                content()
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .active else {
                return
            }

            refresh()
        }
        .task(id: study.intendedStudyEndDate) {
            await refreshAtStudyEnd()
        }
    }

    private func refresh() {
        evaluationDate = study.dateGenerator.generate()
    }

    /// The study period ends without a change to the study, so the step is read again at its end.
    private func refreshAtStudyEnd() async {
        guard let endDate = study.intendedStudyEndDate, endDate > evaluationDate else {
            return
        }

        let delay = max(endDate.timeIntervalSince(study.dateGenerator.generate()), 0)

        // A short margin makes sure the end date has passed when the step is read again.
        try? await Task.sleep(nanoseconds: UInt64((delay + 0.5) * 1_000_000_000))

        guard !Task.isCancelled else {
            return
        }

        refresh()
    }

}
