//
//  DeviceModelIdentifier.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 04.05.26.
//

import Foundation
import UIKit

struct DeviceModelIdentifier {

    typealias SystemInfoProvider = (UnsafeMutablePointer<utsname>) -> Int32

    private let fallbackModelProvider: () -> String?
    private let systemInfoProvider: SystemInfoProvider

    init(
        fallbackModelProvider: @escaping () -> String? = { UIDevice.current.model },
        systemInfoProvider: @escaping SystemInfoProvider = { uname($0) }
    ) {
        self.fallbackModelProvider = fallbackModelProvider
        self.systemInfoProvider = systemInfoProvider
    }

    func model() -> String? {
        hardwareIdentifier() ?? nonEmpty(fallbackModelProvider())
    }

    private func hardwareIdentifier() -> String? {
        var systemInfo = utsname()

        guard systemInfoProvider(&systemInfo) == 0 else {
            return nil
        }

        let capacity = MemoryLayout.size(ofValue: systemInfo.machine)
        let identifier = withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: capacity) { cString in
                String(validatingCString: cString)
            }
        }

        return nonEmpty(identifier)
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, value.isEmpty == false else {
            return nil
        }

        return value
    }

}
