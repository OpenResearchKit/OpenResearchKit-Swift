import XCTest
@testable import OpenResearchKit

final class OpenResearchKitTests: XCTestCase {
    
    func testAppendQueryItems() {
        
        let url = URL(string: "https://example.org?type=survey")!
        
        let additionalQueryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "version", value: "1"),
            URLQueryItem(name: "debug", value: "true"),
        ]
        
        XCTAssertEqual(
            url.appendingQueryItems(additionalQueryItems).absoluteString,
            "https://example.org?type=survey&language=en&version=1&debug=true"
        )
        
    }
    
    func testStudyBuildsSurveyUrl() {
        
        let study = Study(
            title: "",
            subtitle: "",
            duration: 10,
            studyIdentifier: "test",
            universityLogo: nil,
            contactEmail: "test@example.com",
            introductorySurveyURL: URL(string: "https://example.com/intro"),
            concludingSurveyURL: URL(string: "https://example.com/conclusion"),
            fileSubmissionServer: URL(string: "https://example.com/upload")!,
            apiKey: "test",
            uploadFrequency: 10 * 60,
            introSurveyComletionHandler: nil
        )
        
        let url = study.surveyUrl(for: .introductory)
        
        XCTAssertTrue(url!.absoluteString.contains("uuid="))
        
        study.additionalQueryItems = { _ in
            return [URLQueryItem(name: "version", value: "1.0")]
        }
        let other = study.surveyUrl(for: .introductory)
        
        XCTAssertTrue(other!.absoluteString.contains("version=1.0"))
        
    }
    
}
