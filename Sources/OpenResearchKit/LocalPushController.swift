//
//  File.swift
//  
//
//  Created by Frederik Riedel on 08.12.22.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UserNotifications
import UIKit

extension Study {
    public var concludingNotificationRequest: UNNotificationRequest? {
        if let endDate = self.studyEndDate, endDate.isInFuture {
            let content = UNMutableNotificationContent()
            content.title = "Concluding the study"
            content.subtitle = "Thanks for participating. Please fill out one last survey."
            content.body = "It only takes 3 minutes to complete this survey."
            content.categoryIdentifier = self.studyIdentifier
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .active
            }
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            return UNNotificationRequest(identifier: self.studyIdentifier,
                                                            content: content,
                                                            trigger: trigger)
        }
        return nil
    }
}

class LocalPushController {
    
    static let shared = LocalPushController()
    
    func sendLocalNotification(in timeInterval: TimeInterval? = nil, title: String, subtitle: String, body: String, identifier: String, sound: UNNotificationSound = UNNotificationSound.default) {
        
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
    
    private var appName: String {
        let dictionary = Bundle.main.infoDictionary!
        let appName = dictionary["CFBundleName"] as! String
        return appName
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

#endif

