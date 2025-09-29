//
//  SignalService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 29.09.25.
//

import Foundation

public protocol SignalService {
    
    func send(signal: Signal) async throws
    
}
