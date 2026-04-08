//
//  HasTreatmentGroups.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation

public protocol TreatmentGroupProtocol: RawRepresentable<String>, CaseIterable, Equatable, Hashable {
    
    var displayName: String { get }
    
}

public protocol HasTreatmentGroups: AnyObject, GeneralStudy {
    
    associatedtype TreatmentGroup: TreatmentGroupProtocol
    
    var selectedTreatmentGroup: TreatmentGroup? { get set }
    
}

extension HasTreatmentGroups {
    
    private var assignedGroup: String? {
        get {
            return store.get(Study.Keys.AssignedGroup, type: String.self)
        }
        
        set {
            store.update(Study.Keys.AssignedGroup, value: newValue)
            publishChangesOnMain()
        }
    }
    
    internal func setRawAssignedGroup(_ group: String) {
        self.selectedTreatmentGroup = TreatmentGroup(rawValue: group)
    }
    
    public var selectedTreatmentGroup: TreatmentGroup? {
        get {
            guard let assignedGroup else {
                return nil
            }
            
            return TreatmentGroup(rawValue: assignedGroup)
        }
        set {
            assignedGroup = newValue?.rawValue
        }
    }
    
}

import SwiftUI

// MARK: - SwiftUI


@ViewBuilder
func treatmentGroups<T: HasTreatmentGroups>(for study: T, shouldShowDebugTools: Bool) -> some View {
    
    let options = Array(T.TreatmentGroup.allCases)
    
    if shouldShowDebugTools && !options.isEmpty {
        Section(
            header: Text("Treatment Group", bundle: .module),
            footer: Text("Debug and TestFlight only. This overrides the currently stored treatment group for this study.", bundle: .module)
        ) {
            
            ForEach(options, id: \.rawValue) { option in
                Button {
                    study.selectedTreatmentGroup = option
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.displayName)
                                .foregroundStyle(.primary)
                            Text(option.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if study.selectedTreatmentGroup == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("treatment-group-\(option.rawValue)")
            }
        }
    } else {
        EmptyView()
    }
    
}
