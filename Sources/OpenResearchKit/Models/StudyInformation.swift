//
//  StudyInformation.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 27.08.25.
//


import SwiftUI
import UIKit

public struct StudyInformation {
    
    public let title: String
    public let description: String
    public let contactEmail: String
    public let image: UIImage?
    public let detailInfos: String?
    
    public init(
        title: String,
        subtitle: String,
        contactEmail: String,
        image: UIImage?,
        detailInfos: String? = nil
    ) {
        self.title = title
        self.description = subtitle
        self.contactEmail = contactEmail
        self.image = image
        self.detailInfos = detailInfos
    }
    
}
