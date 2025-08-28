//
//  UIViewController+Extensions.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 25.08.25.
//


import Foundation
import UserNotifications
import UIKit

extension UIViewController {
    
    var wrappedInNavigationController: UINavigationController {
        return UINavigationController(rootViewController: self)
    }
    
    static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive || $0.activationState == .foregroundInactive})
        .compactMap({$0 as? UIWindowScene})
        .first?.windows
        .filter({$0.isKeyWindow}).first?
        .rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
    
}