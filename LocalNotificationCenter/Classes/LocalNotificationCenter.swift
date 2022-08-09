//
//  LocalNotificationCenter.swift
//
//  Copyright (c) 2018-2019 Christian Gossain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    /// Initializes the notification center with the given context.
    ///
    /// - parameters:
    ///     - context: A unique context for the notification center. The notification ceneter is limited to manage notifications within this context only.
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
        
        mergedUserInfo.merge(userInfo ?? [:]) {  (current, _) in return current }
        
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
    
    /// Returns a Boolean that indicates if there is a local notification scheduled in the receivers context for the given identifier.
    ///
    /// - parameters:
    ///     - identifier: The unique identifier a previously scheduled notification.
    public func isLocalNotificationScheduled(forIdentifier identifier: String) -> Bool {
        return mutablePendingNotificationRequestsByIdentifier[identifier] != nil
    }
    
    /// Cancels the local notification associated with the given identifer in the receivers context.
    ///
    /// - Note: If there is no notification associated with the given identifier, the method does nothing.
    /// - parameters:
    ///     - identifier: The unique identifier a previously scheduled notification.
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
    
    /// Cancels all scheduled local notificationsin the receivers context.
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
