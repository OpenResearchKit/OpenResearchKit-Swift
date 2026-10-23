//
//  StudyConclusionFinishButton.swift
//  OpenResearchKit
//

import SwiftUI

/// Completes a study that waits for its acknowledgement, using the system's prominent button style.
public struct StudyConclusionFinishButton: View {

    @ObservedObject private var study: LongTermStudy
    private let onFinish: () -> Void

    /// - Parameter onFinish: Called after the study is completed.
    public init(study: LongTermStudy, onFinish: @escaping () -> Void = {}) {
        self.study = study
        self.onFinish = onFinish
    }

    public var body: some View {
        Button {
            if study.acknowledgeCompletion() {
                onFinish()
            }
        } label: {
            Text("Finish participation", bundle: .module)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .prominentStudyActionStyle()
        .disabled(!study.isAwaitingCompletionAcknowledgement)
        .accessibilityIdentifier("finishParticipation")
    }

}

extension View {

    @ViewBuilder
    internal func prominentStudyActionStyle() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glassProminent).controlSize(.large)
        } else {
            self.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).controlSize(.large)
        }
    }

    /// Places `bar` at the bottom safe area, with a soft scroll edge on systems that support it.
    @ViewBuilder
    public func studyBottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26, *) {
            self
                .scrollEdgeEffectStyle(.soft, for: .bottom)
                .safeAreaBar(edge: .bottom) { bar().padding(.horizontal, 24).padding(.bottom, 8) }
        } else {
            self.safeAreaInset(edge: .bottom, spacing: 0) {
                bar().padding(.horizontal, 24).padding(.vertical, 12).frame(maxWidth: .infinity).background(.bar)
            }
        }
    }

}
