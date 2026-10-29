//
//  StudyConclusionView.swift
//  OpenResearchKit
//

import SwiftUI

/// A complete conclusion screen for a study that waits for its completion acknowledgement.
///
/// Present it in a sheet or full-screen cover once ``LongTermStudy/isAwaitingCompletionAcknowledgement``
/// becomes `true`. To show the conclusion inside your own screen, use ``StudyConclusionFlow``, or
/// ``StudyConclusionContent`` and ``StudyConclusionFinishButton``.
public struct StudyConclusionView: View {

    @ObservedObject private var study: LongTermStudy
    private let showsBackground: Bool
    private let onFinish: () -> Void

    /// - Parameter onFinish: Called after the participant finished, for example to dismiss the screen.
    public init(study: LongTermStudy, onFinish: @escaping () -> Void = {}) {
        self.init(study: study, showsBackground: true, onFinish: onFinish)
    }

    /// `StudyConclusionFlow` leaves the background to the screen that hosts it.
    init(study: LongTermStudy, showsBackground: Bool, onFinish: @escaping () -> Void) {
        self.study = study
        self.showsBackground = showsBackground
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
        .background {
            if showsBackground {
                StudyBackground(.fade)
            }
        }
        .studyBottomBar {
            StudyConclusionFinishButton(study: study, onFinish: onFinish)
        }
    }

}
