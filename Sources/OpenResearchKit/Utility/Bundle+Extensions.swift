//
//  Bundle+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 13.09.25.
//

import Foundation

extension Bundle {
    
    /// Indicates whether the app is currently running via TestFlight.
    ///
    /// - Warning: This should **only** be called on `Bundle.main`.
    var isOnTestFlight: Bool {
        guard let path = self.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("sandboxReceipt")
    }

    var isInDebugMode: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.processName == "xctest"
    }
    
}

