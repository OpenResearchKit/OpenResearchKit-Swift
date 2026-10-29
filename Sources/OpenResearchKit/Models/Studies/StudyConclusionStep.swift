//
//  StudyConclusionStep.swift
//  OpenResearchKit
//

import Foundation

/// A step that concludes a study which requires a completion acknowledgement.
public enum StudyConclusionStep: Equatable {

    /// The study period ended and the conclusion survey is pending.
    case survey

    /// The participant has to confirm the end of their participation.
    case acknowledgement

}
