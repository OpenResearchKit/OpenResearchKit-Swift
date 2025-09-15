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
    
    var userConsentDate: Date? { get }
    
    var isDismissedByUser: Bool { get set }
    
    func publishChangesOnMain()
    
    func publishChangesOnMain(completion: @escaping () -> Void)
    
    func showView<Content>(_ view: Content) where Content : View
    
    /// Resets the UUID of the study and clears the study data directories.
    func reset() throws
    
}

extension GeneralStudy {
    
    public var userConsentDate: Date? {
        store.get(Study.Keys.UserConsentDate, type: Date.self)
    }
    
    public var hasUserGivenConsent: Bool {
        return userConsentDate != nil
    }
    
    /// If a study is dismissed by the user, it won't be shown again in the recommended studies.
    /// However, it will still be shown in the list in the settings.
    public var isDismissedByUser: Bool {
        get {
            store.get(Study.Keys.IsDismissedByUser, type: Bool.self) ?? false
        }
        set {
            store.update(Study.Keys.IsDismissedByUser, value: newValue)
            publishChangesOnMain()
        }
    }
    
    public func showView<Content>(_ view: Content) where Content : View {
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: {
            UIViewController.topViewController()?.present(hostingController, animated: true)
        })
        
    }
    
}
