//
//  LocalPushController.swift
//
//
//  Created by Frederik Riedel on 08.12.22.
//

import Foundation
import UserNotifications
import UIKit

class LocalPushController {
    
    static let shared = LocalPushController()
    
    func sendLocalNotification(
        in timeInterval: TimeInterval? = nil,
        title: String,
        subtitle: String,
        body: String,
        identifier: String,
        sound: UNNotificationSound = UNNotificationSound.default
    ) {
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.subtitle = subtitle
        notificationContent.body = body
        notificationContent.categoryIdentifier = identifier
        notificationContent.sound = sound
        
        var notificationTrigger: UNTimeIntervalNotificationTrigger? = nil
        if let timeInterval = timeInterval {
            notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        }
        
        let notificationRequest = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: notificationTrigger)
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
    func askUserForPushPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.showPushPrompt(completion: completion)
                case .denied:
                    completion(false)
                case .authorized:
                    completion(true)
                case .provisional:
                    self.showPushPrompt(completion: completion)
                case .ephemeral:
                    self.showPushPrompt(completion: completion)
                @unknown default:
                    self.showPushPrompt(completion: completion)
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didChangePushStatus"), object: nil)
            }
        }
    }
    
    public func askUserToEnablePushNotificationsForSurveyCompletion(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Notification on study completion", message: "We’ll send you a push notification when the survey is completed in order to fill out the survey completion form.", preferredStyle: .alert)
            let proceed = UIAlertAction(title: "Proceed", style: .default) { _ in
                self.askUserForPushPermission(completion: completion)
            }
            
            alert.addAction(proceed)
            
            UIViewController.topViewController()?.present(alert, animated: true)
        }
    }
    
    private func showPushPrompt(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    private var appName: String {
        let dictionary = Bundle.main.infoDictionary!
        let appName = dictionary["CFBundleName"] as! String
        return appName
    }
    
    static func clearNotifications(with identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [
            identifier
        ])
    }
    
}

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
