//
//  StudyConclusionSurveyView.swift
//  OpenResearchKit
//

import SwiftUI

/// Invites the participant to the conclusion survey once the study period has ended.
///
/// Show it while ``LongTermStudy/pendingConclusionStep`` is ``StudyConclusionStep/survey``, or use
/// ``StudyConclusionFlow``, which switches to it automatically.
public struct StudyConclusionSurveyView: View {

    private let study: LongTermStudy

    public init(study: LongTermStudy) {
        self.study = study
    }

    public var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView {
                Label {
                    Text("Study Period Ended", bundle: .module)
                } icon: {
                    Image(systemName: "flag.checkered")
                }
            } description: {
                description
            } actions: {
                startButton
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Study Period Ended", bundle: .module)
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)

                    description
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                startButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    private var description: Text {
        Text("Thank you for taking part. Please complete the final survey to finish your participation.", bundle: .module)
    }

    private var startButton: some View {
        Button {
            study.showDueSurveyIfNeeded()
        } label: {
            Text("Start Final Survey", bundle: .module)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("startFinalSurvey")
    }

}
