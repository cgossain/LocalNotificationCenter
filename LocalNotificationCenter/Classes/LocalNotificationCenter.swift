//
//  LocalNotificationCenter.swift
//  Pods
//
//  Created by Christian Gossain on 2016-08-26.
//
//

import Foundation
import UserNotifications

/// The LocalNotificationCenter is a light wrapper around the UserNotifications center framework, and only keeps
/// track of only local notifications scheduled by itself.
public class LocalNotificationCenter: NSObject {
    private struct UserInfoKeys {
        static let notificationIdentifier = "LocalNotificationCenterNotificationKey"
    }
    
    /// The default notification center instance.
    public static let `default` = LocalNotificationCenter()
    
    /// A list of all notification requests (managed by the receiver) that are scheduled and waiting to be delivered.
    public var pendingNotificationRequestsByIdentifier: [String : UNNotificationRequest] {
        return mutablePendingNotificationRequestsByIdentifier
    }
    
    /// A mutable list of all notification requests (managed by the receiver) that are scheduled and waiting to be delivered.
    fileprivate var mutablePendingNotificationRequestsByIdentifier: [String : UNNotificationRequest] = [:]
    
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        loadScheduledLocalNotifications()
    }
    
    /// Schedules a local notification with the given parameters.
    ///
    /// - parameters:
    ///     - identifier: The unique identifier for this notification.
    ///     - body: The body of the notification alert.
    ///     - dateMatching: The date components for which to fire the notification on.
    ///     - repeats: A Boolean value indicating whether the system reschedules the notification after it is delivered.
    ///     - userInfo: A dictionary of custom information associated with the notification.
    public func scheduleLocalNotification(withIdentifier identifier: String,
                                          body: String,
                                          dateMatching dateComponents: DateComponents,
                                          repeats: Bool,
                                          userInfo: [String : AnyObject]?) {
        // ignore if the notification is already scheduled
        if isLocalNotificationScheduled(forIdentifier: identifier) {
            return
        }
        
        // add the given user info to the notification content user info
        var notificationContentUserInfo: [AnyHashable : Any] = [LocalNotificationCenter.UserInfoKeys.notificationIdentifier : identifier]
        userInfo?.forEach({ notificationContentUserInfo[$0.key] = $0.value })
        
        // create the local notification content
        let content = UNMutableNotificationContent()
        content.body = body
        content.userInfo = notificationContentUserInfo
        
        // create the notification trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        
        // create a notification request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // add the notification request
        UNUserNotificationCenter.current().add(request) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            
            if error == nil {
                // track the scheduled notification request
                strongSelf.mutablePendingNotificationRequestsByIdentifier[identifier] = request
            }
        }
    }
    
    /// Returns true if a local notification is scheduled for the given key.
    public func isLocalNotificationScheduled(forIdentifier identifier: String) -> Bool {
        return mutablePendingNotificationRequestsByIdentifier[identifier] != nil
    }
    
    /// Cancels the local notification associated with the given key if it is scheduled.
    public func cancelScheduledLocalNotification(forIdentifier identifier: String) {
        // ignore if we did not schedule a notification for this identifier
        if !isLocalNotificationScheduled(forIdentifier: identifier) {
            return
        }
        
        // remove a pending request for the given identifer from the notification center
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // untrack a pending request for the given identifer
        mutablePendingNotificationRequestsByIdentifier[identifier] = nil
    }
    
    /// Cancels all scheduled local notifications.
    public func cancelAllScheduledLocalNotifications() {
        // gather all identifiers scheduled by us
        let identifiersToRemove = Array(pendingNotificationRequestsByIdentifier.keys)
        
        // remove all pending requests that were scheduled by us
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        // untrack all pending requests
        mutablePendingNotificationRequestsByIdentifier.removeAll()
    }
    
}

fileprivate extension LocalNotificationCenter {
    func loadScheduledLocalNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] (requests) in
            guard let strongSelf = self else {
                return
            }
            
            // load only notification requests created by the LocalNotificationCenter class (based on existence of key in userInfo)
            for request in requests {
                guard let identifier = request.content.userInfo[UserInfoKeys.notificationIdentifier] as? String else {
                    continue
                }
                strongSelf.mutablePendingNotificationRequestsByIdentifier[identifier] = request
            }
        }
    }
}
