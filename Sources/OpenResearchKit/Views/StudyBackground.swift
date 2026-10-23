//
//  StudyBackground.swift
//  OpenResearchKit
//

import SwiftUI

/// A background for study screens that follows the app's accent color.
///
/// Use it behind a `ScrollView` or a `List` with a hidden content background.
public struct StudyBackground: View {

    public enum Style {

        /// The grouped system background with a soft accent gradient that fades out from the top.
        case fade

        /// A full-bleed accent gradient with soft highlights and film grain. Use light foreground colors on top.
        case grainy

    }

    private let style: Style

    public init(_ style: Style = .fade) {
        self.style = style
    }

    public var body: some View {
        Group {
            switch style {
            case .fade:
                FadeBackground()
            case .grainy:
                GrainyBackground()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

}

private struct FadeBackground: View {

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)

            LinearGradient(
                colors: [.accentColor, .accentColor.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 306)
            .opacity(0.4)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.35),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

}

private struct GrainyBackground: View {

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.accentColor, .accentColor.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(colors: [.white.opacity(0.35), .clear], center: .topTrailing, startRadius: 0, endRadius: 420)
            Grain()
        }
    }

}

/// Fixed noise, so the grain does not shimmer when the view redraws.
private struct Grain: View {

    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: 0x5EC)
            let count = Int(size.width * size.height / 9)

            for _ in 0..<count {
                let origin = CGPoint(
                    x: .random(in: 0..<max(size.width, 1), using: &generator),
                    y: .random(in: 0..<max(size.height, 1), using: &generator)
                )
                let color: Color = Bool.random(using: &generator) ? .white : .black
                let opacity = Double.random(in: 0.05...0.3, using: &generator)

                context.fill(
                    Path(CGRect(origin: origin, size: CGSize(width: 1, height: 1))),
                    with: .color(color.opacity(opacity))
                )
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }

}

private struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

}

#Preview("Fade") {
    StudyBackground(.fade)
}

#Preview("Grainy") {
    StudyBackground(.grainy)
}
