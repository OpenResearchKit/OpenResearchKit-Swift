//
//  DeviceModelIdentifierTests.swift
//  OpenResearchKit
//
//  Created by OpenResearchKit on 04.05.26.
//

import XCTest

@testable import OpenResearchKit

final class DeviceModelIdentifierTests: XCTestCase {

    func testModelUsesHardwareIdentifierWhenAvailable() {
        let identifier = DeviceModelIdentifier(
            fallbackModelProvider: { "iPhone" },
            systemInfoProvider: { systemInfo in
                systemInfo.pointee = Self.systemInfo(machineBytes: Array("iPhone16,2".utf8) + [0])
                return 0
            }
        )

        XCTAssertEqual(identifier.model(), "iPhone16,2")
    }

    func testModelFallsBackWhenUnameFails() {
        let identifier = DeviceModelIdentifier(
            fallbackModelProvider: { "iPhone" },
            systemInfoProvider: { _ in -1 }
        )

        XCTAssertEqual(identifier.model(), "iPhone")
    }

    func testModelFallsBackWhenHardwareIdentifierIsInvalidUTF8() {
        let identifier = DeviceModelIdentifier(
            fallbackModelProvider: { "iPhone" },
            systemInfoProvider: { systemInfo in
                systemInfo.pointee = Self.systemInfo(machineBytes: [0xFF, 0])
                return 0
            }
        )

        XCTAssertEqual(identifier.model(), "iPhone")
    }

    private static func systemInfo(machineBytes: [UInt8]) -> utsname {
        var systemInfo = utsname()

        withUnsafeMutableBytes(of: &systemInfo.machine) { buffer in
            for (index, byte) in machineBytes.prefix(buffer.count).enumerated() {
                buffer[index] = byte
            }
        }

        return systemInfo
    }

}
