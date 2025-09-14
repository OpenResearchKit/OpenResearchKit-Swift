//
//  StudyInformation.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 27.08.25.
//


import SafariServices
import SwiftUI
import UIKit

public struct StudyInformation {
    
    public let title: String
    public let subtitle: String
    public let contactEmail: String
    public let image: UIImage?
    public let duration: TimeInterval?
    public let detailInfos: String?
    
    public init(
        title: String,
        subtitle: String,
        contactEmail: String,
        image: UIImage?,
        duration: TimeInterval?,
        detailInfos: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.contactEmail = contactEmail
        self.image = image
        self.duration = duration
        self.detailInfos = detailInfos
    }
    
}
