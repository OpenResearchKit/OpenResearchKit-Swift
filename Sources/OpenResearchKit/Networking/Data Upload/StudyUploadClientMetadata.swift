//
//  StudyUploadClientMetadata.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 04.05.26.
//

import Foundation
import UIKit

struct StudyUploadClientMetadata {

    let clientVersion: String?
    let clientBuild: String?
    let clientPlatform: String?
    let clientOSVersion: String?
    let clientDeviceModel: String?
    let clientTimezone: String?
    let clientLocale: String?
    let clientLocales: String?

    static func current(bundle: Bundle = .main) -> StudyUploadClientMetadata {
        let clientLocale = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        let clientLocales = Locale.preferredLanguages.joined(separator: ",")

        return StudyUploadClientMetadata(
            clientVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            clientBuild: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            clientPlatform: "iOS",
            clientOSVersion: UIDevice.current.systemVersion,
            clientDeviceModel: DeviceModelIdentifier().model(),
            clientTimezone: TimeZone.current.identifier,
            clientLocale: clientLocale,
            clientLocales: clientLocales
        )
    }

}
