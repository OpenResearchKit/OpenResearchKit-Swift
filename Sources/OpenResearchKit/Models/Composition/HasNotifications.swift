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
