//
//  ResearchWebView.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//


import SwiftUI
import WebKit
import UIKit

public struct ResearchWebView: UIViewRepresentable {
    
    public let url: URL
    public let completion: (Bool, [String: String]) -> ()
    private let onInitialLoadStateChange: ((Bool) -> Void)?
    
    public init(
        url: URL,
        completion: @escaping (Bool, [String: String]) -> (),
        onInitialLoadStateChange: ((Bool) -> Void)? = nil
    ) {
        self.url = url
        self.completion = completion
        self.onInitialLoadStateChange = onInitialLoadStateChange
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.observeInitialLoadingState(of: webView)
        
        DispatchQueue.main.async {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(
            completion: completion,
            onInitialLoadStateChange: onInitialLoadStateChange
        )
    }
    
    // MARK: - WKNavigationDelegate -
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        
        internal init(
            completion: @escaping (Bool, [String: String]) -> (),
            onInitialLoadStateChange: ((Bool) -> Void)?
        ) {
            self.completion = completion
            self.onInitialLoadStateChange = onInitialLoadStateChange
        }
        
        let completion: (Bool, [String: String]) -> ()
        let onInitialLoadStateChange: ((Bool) -> Void)?
        var loadingObservation: NSKeyValueObservation?
        var hasCompletedInitialLoad = false
        
        func observeInitialLoadingState(of webView: WKWebView) {
            loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                guard let self, !self.hasCompletedInitialLoad else { return }
                
                DispatchQueue.main.async {
                    self.onInitialLoadStateChange?(webView.isLoading)
                }
            }
        }
        
        func completeInitialLoadIfNeeded() {
            guard !hasCompletedInitialLoad else { return }
            
            hasCompletedInitialLoad = true
            onInitialLoadStateChange?(false)
            loadingObservation = nil
        }
        
        public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            if let url = webView.url {
                let urlString = url.absoluteString
                if urlString.contains("survey-callback/success") {
                    self.completion(true, url.queryParameters ?? [:])
                } else if urlString.contains("survey-callback/failed") {
                    self.completion(false, url.queryParameters ?? [:])
                }
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            completeInitialLoadIfNeeded()
        }
        
        public func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            completeInitialLoadIfNeeded()
        }
        
        public func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            completeInitialLoadIfNeeded()
        }
        
    }
}
