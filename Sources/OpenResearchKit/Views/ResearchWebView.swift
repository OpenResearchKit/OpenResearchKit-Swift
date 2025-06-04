//
//  ResearchWebView.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//


import SwiftUI
import WebKit
import UIKit
import SwiftUI
import WebKit

public struct ResearchWebView: UIViewRepresentable {
    
    public let url: URL
    public let completion: (Bool, [String: String]) -> ()
    
    public init(url: URL, completion: @escaping (Bool, [String: String]) -> ()) {
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
        
        internal init(completion: @escaping (Bool, [String: String]) -> ()) {
            self.completion = completion
        }
        
        let completion: (Bool, [String: String]) -> ()
        
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
            
        }
        
    }
}