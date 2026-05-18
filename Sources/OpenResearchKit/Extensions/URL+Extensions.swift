//
//  URL+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 28.08.25.
//


import Foundation

extension URL {

    func appendingQueryItem(name: String, value: String?) -> URL {

        var urlComponents = URLComponents(string: absoluteString)!

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

        // Create query item
        let queryItem = URLQueryItem(name: name, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        return urlComponents.url!
    }
    
    func appendingQueryItems(_ queryItems: [URLQueryItem]) -> URL {
        
        var urlComponents = URLComponents(string: absoluteString)!
        
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
        
        return urlComponents.url!
        
    }
    
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }

}
