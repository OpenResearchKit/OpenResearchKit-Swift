//
//  EnrollmentService.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 01.05.26.
//


import OSLog
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public protocol EnrollmentService {

    func enroll(study: Study) async throws

}