//
//  StudyConclusionContent.swift
//  OpenResearchKit
//

import SwiftUI

/// The thank-you message and summary for a study that waits for its completion acknowledgement.
///
/// Embed it in a screen of your own, for example in a standalone study interface, or use
/// ``StudyConclusionView`` for a complete screen. Pair it with ``StudyConclusionFinishButton``.
public struct StudyConclusionContent: View {

    @ObservedObject private var study: LongTermStudy

    public init(study: LongTermStudy) {
        self.study = study
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            facts
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
                .padding(.bottom, 8)

            Text("Thank you for taking part", bundle: .module)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            Text("The study has ended. Finish to complete your participation.", bundle: .module)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 20) {
            StudyConclusionFact(
                systemImage: "calendar",
                title: Text("Study period ended", bundle: .module),
                detail: endDateText
            )

            StudyConclusionFact(
                systemImage: "pause.circle",
                title: Text("Data collection stopped", bundle: .module),
                detail: Text("No further data is recorded.", bundle: .module)
            )

            if study.concludingSurveyURL != nil {
                StudyConclusionFact(
                    systemImage: "checkmark.circle",
                    title: Text("Final survey completed", bundle: .module),
                    detail: Text("Thank you for answering the final questions.", bundle: .module)
                )
            }
        }
    }

    private var endDateText: Text {
        
        if let endDate = study.intendedStudyEndDate {
            return Text(endDate.formatted(date: .long, time: .shortened))
        }

        return Text("The study period is over.", bundle: .module)
        
    }

}

struct StudyConclusionFact: View {

    let systemImage: String
    let title: Text
    let detail: Text

    var body: some View {
        
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                title.font(.headline)
                detail.font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        
    }

}
