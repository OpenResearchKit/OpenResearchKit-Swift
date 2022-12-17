#if !os(watchOS)
import UIKit
import SwiftUI
import WebKit

// this is a web view on purpose so that users cant share the URL
public struct SurveyWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var study: Study
    let surveyType: SurveyType
    
    @State var showPushExplanation: Bool = false
    
    public init(study: Study, surveyType: SurveyType) {
        self.study = study
        self.surveyType = surveyType
    }
    public var body: some View {
        NavigationView {
            OpenResearchWebView(url: study.surveyUrl(for: surveyType), completion: { success in
                if surveyType == .introductory {
                    if success {
                        // schedule push notification for study completed date -> in 6 weeks
                        // automatically opens completion survey
                        study.saveUserConsentHasBeenGiven(consentTimestamp: Date())
                        presentationMode.wrappedValue.dismiss()
                        
                        let alert = UIAlertController(title: "Post-Study-Questionnaire", message: "We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.", preferredStyle: .alert)
                        let proceedAction = UIAlertAction(title: "Proceed", style: .default) { _ in
                            LocalPushController.shared.askUserForPushPermission { success in
                                var pushDuration = study.duration
                                #if DEBUG
                                pushDuration = 10
                                #endif
                                LocalPushController.shared.sendLocalNotification(in: pushDuration, title: "Concluding our Study", subtitle: "Please fill out the post-study-survey", body: "It’s just 3 minutes to complete the survey.", identifier: "survey-completion-notification")
                            }
                        }
                        alert.addAction(proceedAction)
                        UIViewController.topViewController()?.present(alert, animated: true)
                        
                        self.showPushExplanation = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else if surveyType == .completion {
                    presentationMode.wrappedValue.dismiss()
                    study.hasCompletedTerminationSurvey = true
                }
            })
                .navigationTitle("Survey")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}

public struct OpenResearchWebView: UIViewRepresentable {
    
    var url: URL
    var completion: (Bool) -> ()
    
    public init(url: URL, completion: @escaping (Bool) -> Void) {
        self.url = url
        self.completion = completion
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        DispatchQueue.main.async {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completion)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        internal init(completion: @escaping (Bool) -> ()) {
            self.completion = completion
        }
        
        var completion: (Bool) -> ()
        
        public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            if let url = webView.url {
                let urlString = url.absoluteString
                if urlString.contains("survey-callback/success") {
                    DispatchQueue.main.async {
                        self.completion(true)
                    }
                } else if urlString.contains("survey-callback/failed") {
                    DispatchQueue.main.async {
                        self.completion(false)
                    }
                }
            }
        }
    }
}
#endif
