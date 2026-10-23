//
//  StudyConclusionLocalizationTests.swift
//  OpenResearchKit
//

import Foundation
import Testing

@testable import OpenResearchKit

@Suite("Study conclusion localization")
struct StudyConclusionLocalizationTests {

    /// The keys used by `StudyConclusionContent` and `StudyConclusionFinishButton`.
    private static let keys = [
        "Thank you for taking part",
        "%@ has ended. Finish to complete your participation.",
        "Study period ended",
        "The study period is over.",
        "Data collection stopped",
        "No further data is recorded.",
        "Final survey completed",
        "Thank you for answering the final questions.",
        "Finish participation"
    ]

    @Test("Every conclusion string is translated", arguments: ["en", "da"])
    func everyStringIsTranslated(localization: String) throws {
        let table = try strings(for: localization)

        for key in Self.keys {
            let value = table[key]
            #expect(value != nil, "Missing \(localization) translation for \"\(key)\"")
            #expect(value?.isEmpty == false)
        }
    }

    @Test("The title placeholder survives translation", arguments: ["en", "da"])
    func placeholderIsKept(localization: String) throws {
        let value = try #require(try strings(for: localization)["%@ has ended. Finish to complete your participation."])

        #expect(value.components(separatedBy: "%@").count == 2)
    }

    @Test("Danish strings differ from the English source")
    func danishIsTranslated() throws {
        let english = try strings(for: "en")
        let danish = try strings(for: "da")

        for key in Self.keys {
            #expect(danish[key] != english[key], "\"\(key)\" is not translated to Danish")
        }
    }

    private func strings(for localization: String) throws -> [String: String] {
        let path = try #require(
            Bundle.module.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: localization)
        )

        return try #require(NSDictionary(contentsOfFile: path) as? [String: String])
    }

}
