//
//  HasNotifications.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 15.09.25.
//

import UIKit

/// A protocol that enables studies to support local push notifications for research participants.
///
/// Conforming to this protocol allows studies to schedule and manage local notifications
/// that can remind participants about surveys, study milestones, or completion deadlines.
/// The protocol provides a standardized way to handle notification permissions and registration
/// within the OpenResearchKit framework.
///
/// ## Protocol Requirements
///
/// Conforming types must implement:
/// - `shouldHaveNotifications()`: Determines if the study uses notifications
/// - `registerNotifications()`: Sets up study-specific notifications after consent
///
/// ## Notification Lifecycle
///
/// 1. **Consent Phase**: When a user consents to participate, `prepareLocalNotifications` is called
/// 2. **Permission Request**: If notifications are enabled, the user is asked for permission
/// 3. **Registration**: Study-specific notifications are registered via `registerNotifications()`
/// 4. **Delivery**: Notifications are delivered at scheduled times throughout the study
///
/// ## Usage Example
///
/// ```swift
/// class MyResearchStudy: Study, HasNotifications {
///
///     func shouldHaveNotifications() -> Bool {
///         return true  // Enable notifications for this study
///     }
///
///     func registerNotifications() {
///         // Schedule study completion reminder
///         let endDate = studyStartDate.addingTimeInterval(duration)
///         LocalPushController.shared.sendLocalNotification(
///             at: endDate,
///             title: "Study Complete",
///             body: "Please complete your final survey",
///             identifier: "study-completion-\(studyIdentifier)"
///         )
///
///         // Schedule mid-study survey reminder
///         if let midSurvey = midStudySurvey {
///             let reminderDate = studyStartDate.addingTimeInterval(midSurvey.showAfter)
///             LocalPushController.shared.sendLocalNotification(
///                 at: reminderDate,
///                 title: "Mid-Study Survey",
///                 body: "Time for your mid-study survey",
///                 identifier: "mid-survey-\(studyIdentifier)"
///             )
///         }
///     }
/// }
/// ```
public protocol HasNotifications: GeneralStudy {

    /// Determines whether this study should use local push notifications.
    ///
    /// This method is called during the consent process to check if the study
    /// requires notification functionality. If `true`, the framework will:
    /// 1. Show an explanatory alert to the user
    /// 2. Request notification permissions from the system
    /// 3. Call `registerNotifications()` to set up study-specific notifications
    ///
    /// ## Implementation Guidelines
    ///
    /// Return `true` if your study needs to:
    /// - Remind participants about surveys or questionnaires
    /// - Notify users when the study period ends
    /// - Send periodic reminders during the study
    /// - Alert participants about important study events
    ///
    /// ## Default Implementation
    ///
    /// The protocol provides a default implementation that returns `false`,
    /// so studies without notification needs don't require any implementation.
    ///
    /// ## Example Implementation
    ///
    /// ```swift
    /// func shouldHaveNotifications() -> Bool {
    ///     // Enable notifications for studies longer than 1 day
    ///     return duration > 24 * 60 * 60
    /// }
    /// ```
    ///
    /// - Returns: `true` if the study should use local notifications, `false` otherwise.
    ///
    /// - Note: This method is called on the main thread during the consent process.
    ///
    /// - SeeAlso: `registerNotifications()` for implementing notification scheduling
    func shouldHaveNotifications() -> Bool

    /// Registers and schedules study-specific local notifications.
    ///
    /// This method is called automatically after the user has given consent to participate
    /// in the study and the notification permission flow has completed. It's where you
    /// should implement all study-specific notification scheduling logic.
    ///
    /// ## When This Method Is Called
    ///
    /// - After `shouldHaveNotifications()` returns `true`
    /// - After the user sees the notification explanation alert
    /// - After the system permission request completes
    /// - Before the consent completion callback is executed
    ///
    /// ## Implementation Responsibilities
    ///
    /// In your implementation, you should:
    /// 1. Calculate appropriate notification timing based on study parameters
    /// 2. Create descriptive notification content
    /// 3. Use unique identifiers for each notification
    /// 4. Handle edge cases (study already completed, invalid dates, etc.)
    ///
    /// ## Common Notification Scenarios
    ///
    /// - **Study Completion**: Notify when the study period ends
    /// - **Survey Reminders**: Remind about pending questionnaires
    /// - **Milestone Notifications**: Alert at study milestones
    /// - **Check-in Reminders**: Periodic participation reminders
    ///
    /// ## Example Implementation
    ///
    /// ```swift
    /// func registerNotifications() {
    ///     let studyEndDate = Date().addingTimeInterval(duration)
    ///
    ///     // Completion notification
    ///     LocalPushController.shared.sendLocalNotification(
    ///         at: studyEndDate,
    ///         title: "Study Completed",
    ///         body: "Thank you for participating! Please complete your final survey.",
    ///         identifier: "completion-\(studyIdentifier)"
    ///     )
    ///
    ///     // Mid-study reminder (if applicable)
    ///     if let midSurvey = midStudySurvey {
    ///         let midDate = Date().addingTimeInterval(midSurvey.showAfter)
    ///         LocalPushController.shared.sendLocalNotification(
    ///             at: midDate,
    ///             title: "Mid-Study Survey",
    ///             body: "Time for your mid-study questionnaire",
    ///             identifier: "mid-survey-\(studyIdentifier)"
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// ## Default Implementation
    ///
    /// The protocol provides an empty default implementation, so studies that
    /// enable notifications but don't need custom scheduling can rely on it.
    ///
    /// - SeeAlso:
    ///   - `shouldHaveNotifications()` for enabling notification support
    func registerNotifications()

}

extension HasNotifications {

    /// Prepares and sets up local notifications for the study after user consent.
    ///
    /// This method is automatically called when a user gives consent to participate in a study.
    /// It handles the complete notification setup flow including:
    /// 1. Checking if the study requires notifications via `shouldHaveNotifications()`
    /// 2. Presenting a user-friendly alert explaining why notifications are needed
    /// 3. Requesting push notification permissions from the system
    /// 4. Calling `registerNotifications()` to set up study-specific notifications
    ///
    /// ## Notification Flow
    ///
    /// The method follows this sequence:
    /// - If `shouldHaveNotifications()` returns `false`, the completion handler is called immediately
    /// - If notifications are required, displays an alert to inform the user about post-study questionnaires
    /// - Upon user confirmation, requests system notification permissions
    /// - Calls `registerNotifications()` regardless of permission grant status
    /// - Executes the completion handler when the flow is complete
    ///
    /// ## Alert Content
    ///
    /// The alert displays localized content:
    /// - **Title**: "Post-Study-Questionnaire" (localized)
    /// - **Message**: "We'll send you a push notification when the study is concluded to fill out the post-questionnaire." (localized)
    /// - **Action**: "Ok" button to proceed with permission request
    ///
    /// ## Unit Testing Considerations
    ///
    /// When running unit tests (`Bundle.main.isRunningUnitTests` is `true`), the completion
    /// handler is called immediately to prevent UI interactions during automated testing.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // Called automatically during consent process
    /// study.saveUserConsentHasBeenGiven(consentTimestamp: Date()) {
    ///     // Notifications are now prepared
    ///     print("User consent saved and notifications prepared")
    /// }
    /// ```
    ///
    /// ## Implementation Notes
    ///
    /// - Permission denial doesn't prevent `registerNotifications()` from being called
    /// - The alert is presented on the topmost view controller in the hierarchy
    /// - All UI operations are performed on the main thread
    ///
    /// - Parameter completion: A closure executed when the notification preparation is complete.
    ///   Called immediately if notifications are disabled, or after the permission flow when enabled.
    ///   Defaults to an empty closure if not provided.
    ///
    /// - Important: This method should not be called directly. It's automatically invoked
    ///   as part of the user consent process in `saveUserConsentHasBeenGiven(consentTimestamp:completion:)`.
    ///
    /// - Note: The actual notification scheduling should be implemented in the `registerNotifications()`
    ///   method of conforming types.
    ///
    /// - SeeAlso:
    ///   - `shouldHaveNotifications()` for controlling whether notifications are used
    ///   - `registerNotifications()` for implementing study-specific notification scheduling
    ///   - `LocalPushController.shared.askUserForPushPermission(completion:)` for the permission request implementation
    internal func prepareLocalNotifications(completion: @escaping () -> Void = {}) {

        if shouldHaveNotifications() {

            let alert = UIAlertController(
                title: NSLocalizedString(
                    "Post-Study-Questionnaire", bundle: Bundle.module, comment: ""),
                message: NSLocalizedString(
                    "We’ll send you a push notification when the study is concluded to fill out the post-questionnaire.",
                    bundle: Bundle.module, comment: ""),
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

    public func shouldHaveNotifications() -> Bool {
        return false
    }

    public func registerNotifications() {

    }

}
