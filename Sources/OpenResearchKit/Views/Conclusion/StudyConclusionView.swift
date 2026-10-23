//
//  StudyConclusionView.swift
//  OpenResearchKit
//

import SwiftUI

/// A complete conclusion screen for a study that waits for its completion acknowledgement.
///
/// Present it in a sheet or full-screen cover once ``LongTermStudy/isAwaitingCompletionAcknowledgement``
/// becomes `true`. To show the conclusion inside your own screen, use ``StudyConclusionContent`` and
/// ``StudyConclusionFinishButton`` instead.
public struct StudyConclusionView: View {

    @ObservedObject private var study: LongTermStudy
    private let onFinish: () -> Void

    /// - Parameter onFinish: Called after the participant finished, for example to dismiss the screen.
    public init(study: LongTermStudy, onFinish: @escaping () -> Void = {}) {
        self.study = study
        self.onFinish = onFinish
    }

    public var body: some View {
        ScrollView {
            StudyConclusionContent(study: study)
                .padding(.horizontal, 24)
                .padding(.top, 48)
                .padding(.bottom, 24)
                .frame(maxWidth: 560, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background { StudyBackground(.fade) }
        .studyBottomBar {
            StudyConclusionFinishButton(study: study, onFinish: onFinish)
        }
    }

}
