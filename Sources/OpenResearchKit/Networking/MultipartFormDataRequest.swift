//
//  MultipartFormDataRequest.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 04.06.25.
//

import Foundation

public protocol JSONConvertible {}
extension String: JSONConvertible {}
extension Int: JSONConvertible {}
extension Double: JSONConvertible {}
extension NSNumber: JSONConvertible {}
extension NSString: JSONConvertible {}
extension Bool: JSONConvertible {}
extension Array<JSONConvertible>: JSONConvertible {}
extension Dictionary<String, JSONConvertible>: JSONConvertible {}

struct MultipartFormDataRequest {
    
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    func addDataField(named name: String, filename: String, data: Data, mimeType: String) {
        httpBody.append(dataFormField(named: name, filename: filename, data: data, mimeType: mimeType))
    }

    private func dataFormField(
        named name: String,
        filename: String,
        data: Data,
        mimeType: String
    ) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }
    
    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody.append("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}

extension NSMutableData {
    
    func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
    
}

extension URLSession {
    
    func dataTask(
        with request: MultipartFormDataRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return dataTask(with: request.asURLRequest(), completionHandler: completionHandler)
    }
    
}
