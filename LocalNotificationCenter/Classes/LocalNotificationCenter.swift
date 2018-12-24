//
//  LocalNotificationCenter.swift
//  Pods
//
//  Created by Christian Gossain on 2016-08-26.
//
//

import Foundation
import UserNotifications

public class LocalNotificationCenter {
    private struct UserInfoKeys {
        static let notificationContext = "com.localnotificationcenter.userinfokeys.context"
        static let notificationIdentifier = "com.localnotificationcenter.userinfokeys.identifier"
    }
    
    /// The default notification center instance.
    public static let `default` = LocalNotificationCenter(context: "com.localnotificationcenter.context.default")
    
    /// The context of the receiver.
    public let context: String
    
    /// A list of all notification requests (managed by the receiver) that are scheduled and waiting to be delivered.
    public var pendingNotificationRequestsByIdentifier: [String : UNNotificationRequest] {
        return mutablePendingNotificationRequestsByIdentifier
    }
    
    /// A mutable list of all notification requests (managed by the receiver) that are scheduled and waiting to be delivered.
    fileprivate var mutablePendingNotificationRequestsByIdentifier: [String : UNNotificationRequest] = [:]
    
    
    // MARK: - Lifecycle
    init(context: String) {
        self.context = context
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
                                          userInfo: [String : AnyObject]? = nil) {
        // ignore if the notification is already scheduled
        if isLocalNotificationScheduled(forIdentifier: identifier) {
            return
        }
        
        // create the base user info
        var notificationContentUserInfo: [AnyHashable : Any] = [LocalNotificationCenter.UserInfoKeys.notificationContext : self.context,
                                                                LocalNotificationCenter.UserInfoKeys.notificationIdentifier : identifier]
        
        // append any additional externally provided user info
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
        let identifiersToRemove = Array(mutablePendingNotificationRequestsByIdentifier.keys)
        
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
                // do not load any notification requests outside our context
                guard let context = request.content.userInfo[UserInfoKeys.notificationContext] as? String, context == strongSelf.context else {
                    continue
                }
                
                // get the notification requests identifier
                guard let identifier = request.content.userInfo[UserInfoKeys.notificationIdentifier] as? String else {
                    continue
                }
                
                strongSelf.mutablePendingNotificationRequestsByIdentifier[identifier] = request
            }
        }
    }
}
