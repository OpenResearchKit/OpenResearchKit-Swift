//
//  HasNotifications.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import UIKit

public protocol HasNotifications: GeneralStudy {
    
    func shouldHaveNotifications() -> Bool
    
    func registerNotifications()
    
}

public extension HasNotifications {
    
    internal func prepareLocalNotifications(completion: @escaping () -> Void = {}) {
        
        if shouldHaveNotifications() {
            
            let alert = UIAlertController(
                title: NSLocalizedString("Post-Study-Questionnaire", bundle: Bundle.module, comment: ""),
                message: NSLocalizedString("We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.", bundle: Bundle.module, comment: ""),
                preferredStyle: .alert
            )
            
            let proceedAction = UIAlertAction(title: "Ok", style: .default) { _ in
                LocalPushController.shared.askUserForPushPermission { success in
                    
                    // todo: does it make sense to also register them when no push permission was given?
                    
                    self.registerNotifications()
                    
                    completion()
                    
                }
            }
            
            alert.addAction(proceedAction)
            
            UIViewController.topViewController()?.present(alert, animated: true)
            
            if Bundle.main.isRunningUnitTests {
                completion()
            }
            
        } else {
            completion()
        }
        
    }
    
    /// Return `true` if you want your study to have local push notifications.
    /// Override `registerNotifications` to register your notifications.
    func shouldHaveNotifications() -> Bool {
        return false
    }
    
    /// Place to register study related notifications. It is called after the user consented to take part in the study and if they
    func registerNotifications() {
        
    }
    
}
