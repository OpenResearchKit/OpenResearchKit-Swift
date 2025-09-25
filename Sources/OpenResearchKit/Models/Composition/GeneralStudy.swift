//
//  HasStudyStore.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 14.09.25.
//

import Foundation
import SwiftUI

public protocol GeneralStudy: AnyObject, ObservableObject {
    
    var store: StudyKeyValueStore { get }
    
    var studyIdentifier: String { get }
    
    var userIdentifier: String { get }
    
    var userConsentDate: Date? { get }
    
    /// If a study is dismissed by the user, it won't be shown again in the recommended studies.
    /// However, it will still be shown in the list in the settings.
    var isDismissedByUser: Bool { get set }
    
    /// If a study returns being active, it is the primary study presented in the app.
    var isActive: Bool { get }
    
    // MARK: - Eligibility
    
    func isEligible() async -> Bool
    
    func showView<Content>(_ view: Content) where Content : View
    
    /// Resets the UUID of the study and clears the study data directories.
    func reset() throws
    
    func didTerminateParticipation(terminationDate: Date)
    
    /// Should trigger the `objectWillChange` publisher of the `ObservableObject`.
    func publishChangesOnMain()
    
    /// Should trigger the `objectWillChange` publisher of the `ObservableObject`.
    func publishChangesOnMain(completion: @escaping () -> Void)
    
    // MARK: - Used for testing
    
    var dateGenerator: DateGenerator { get }
    
}

extension GeneralStudy {
    
    public var userConsentDate: Date? {
        store.get(Study.Keys.UserConsentDate, type: Date.self)
    }
    
    public var hasUserGivenConsent: Bool {
        return userConsentDate != nil
    }
    
    public var isDismissedByUser: Bool {
        get {
            store.get(Study.Keys.IsDismissedByUser, type: Bool.self) ?? false
        }
        set {
            store.update(Study.Keys.IsDismissedByUser, value: newValue)
            publishChangesOnMain()
        }
    }
    
    /// If a user terminated their study participation before completion, we save that date
    /// and save it in the metadata of the study file as additional datapoints to indicate that
    /// the user did not complete the entire treatment duration.
    public private(set) var terminationBeforeCompletionDate: Date? {
        get {
            store.get(Study.Keys.TerminatedByUserDate, type: Date.self)
        }
        
        set {
            store.update(Study.Keys.TerminatedByUserDate, value: newValue)
            publishChangesOnMain()
        }
    }
    
    /// The user terminated their study participation before completion indicating that
    /// the user did not complete the entire treatment duration.
    public var wasTerminatedBeforeCompletion: Bool {
        return terminationBeforeCompletionDate != nil
    }
    
    /// Terminates the study participation immediately by saving the termination date and
    /// giving a callback to the `didTerminateParticipation(terminationDate: )` function of the study.
    public func terminateParticipationImmediately() {
        let terminationDate = dateGenerator.generate()
        self.terminationBeforeCompletionDate = terminationDate
        self.didTerminateParticipation(terminationDate: terminationDate)
    }
    
    public func showView<Content>(_ view: Content) where Content : View {
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: {
            UIViewController.topViewController()?.present(hostingController, animated: true)
        })
        
    }
    
}
