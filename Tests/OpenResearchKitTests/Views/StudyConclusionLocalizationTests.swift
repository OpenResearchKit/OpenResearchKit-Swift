//
//  StudyConclusionLocalizationTests.swift
//  OpenResearchKit
//

import Foundation
import Testing

@testable import OpenResearchKit

@Suite("Study conclusion localization")
struct StudyConclusionLocalizationTests {

    /// The keys used by the views in `Views/Conclusion`.
    private static let keys = [
        "Thank you for taking part",
        "The study has ended. Finish to complete your participation.",
        "Study period ended",
        "The study period is over.",
        "Data collection stopped",
        "No further data is recorded.",
        "Final survey completed",
        "Thank you for answering the final questions.",
        "Finish participation",
        "Study Period Ended",
        "Thank you for taking part. Please complete the final survey to finish your participation.",
        "Start Final Survey"
    ]

    @Test("Every conclusion string is in the English table")
    func everyStringIsInEnglishTable() throws {
        let path = try #require(
            Bundle.module.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en")
        )
        let table = try #require(NSDictionary(contentsOfFile: path) as? [String: String])

        for key in Self.keys {
            #expect(table[key]?.isEmpty == false, "Missing English entry for \"\(key)\"")
        }
    }

}
