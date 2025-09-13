import XCTest
@testable import OpenResearchKit

extension UploadConfiguration {
    
    static let dummy: UploadConfiguration = .init(
        fileSubmissionServer: URL(string: "https://example.org/upload")!,
        uploadFrequency: 60 * 60 * 24,
        apiKey: ""
    )
    
}

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
            studyIdentifier: "test",
            studyInformation: StudyInformation(
                title: "",
                subtitle: "",
                contactEmail: "test@example.com",
                image: nil,
                duration: 10,
            ),
            uploadConfiguration: .dummy,
            introductorySurveyURL: URL(string: "https://example.com/intro"),
            concludingSurveyURL: URL(string: "https://example.com/conclusion"),
            introSurveyCompletionHandler: nil
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
