//
//  LocalNotificationCenter.swift
//
//  Copyright (c) 2022 Christian Gossain
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

/// An object for managing the local notifications for your app or app extension within a given namespace.
public class LocalNotificationCenter {
    
    /// The default notification center instance.
    public static let `default` = LocalNotificationCenter(context: "com.localnotificationcenter.context.default")
    
    /// The context.
    public let context: String
    
    /// A list of all notification requests (managed by the receiver) that are scheduled and waiting to be delivered.
    public private(set) var pendingNotificationRequestsByIdentifier: [String : UNNotificationRequest] = [:]
    
    
    // MARK: - Lifecycle
    
    /// Creates and returns a new instance of the local notification center.
    ///
    /// - Parameters:
    ///     - context: A unique context for the notification center. Notifications scheduled by the receiver are scoped to this given context only.
    init(context: String) {
        self.context = context
        loadScheduledLocalNotifications()
    }
    
    /// Schedules a local notification associated with the receivers context using the given parameters.
    ///
    /// - Parameters:
    ///     - identifier: The unique identifier for this notification.
    ///     - body: The localized message to display in the notification alert.
    ///     - dateMatching: The temporal information to use when constructing the trigger. Provide only the date components that are relevant for your trigger.
    ///     - repeats: Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the system delivers the notification.
    ///     - userInfo: A dictionary of custom information associated with the notification.
    public func scheduleLocalNotification(withIdentifier identifier: String,
                                          body: String,
                                          dateMatching dateComponents: DateComponents,
                                          repeats: Bool,
                                          userInfo: [AnyHashable : Any]? = nil) {
        guard !isLocalNotificationScheduled(forIdentifier: identifier) else {
            return
        }
        
        var mergedUserInfo: [AnyHashable : Any] = [
            LocalNotificationCenter.UserInfoKeys.notificationContext : self.context,
            LocalNotificationCenter.UserInfoKeys.notificationIdentifier : identifier
        ]
        
        mergedUserInfo.merge(userInfo ?? [:]) {  (current, _) in return current }
        
        let content = UNMutableNotificationContent()
        content.body = body
        content.userInfo = mergedUserInfo
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] (error) in
            guard let strongSelf = self else {
                return
            }
            
            if error == nil {
                strongSelf.pendingNotificationRequestsByIdentifier[identifier] = request
            }
        }
    }
    
    /// Returns a Boolean that indicates if there is a local notification scheduled in the receivers context for the given identifier.
    ///
    /// - Parameters:
    ///     - identifier: The unique identifier a previously scheduled notification.
    public func isLocalNotificationScheduled(forIdentifier identifier: String) -> Bool {
        return pendingNotificationRequestsByIdentifier[identifier] != nil
    }
    
    /// Cancels the local notification associated with the given identifer in the receivers context.
    ///
    /// - Parameters:
    ///     - identifier: The unique identifier a previously scheduled notification.
    /// - Note: If there is no notification associated with the given identifier, the method does nothing.
    public func cancelScheduledLocalNotification(forIdentifier identifier: String) {
        guard isLocalNotificationScheduled(forIdentifier: identifier) else {
            return
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        pendingNotificationRequestsByIdentifier[identifier] = nil
    }
    
    /// Cancels all scheduled local notifications associated with the receivers context.
    public func cancelAllScheduledLocalNotifications() {
        let identifiers = Array(pendingNotificationRequestsByIdentifier.keys)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        pendingNotificationRequestsByIdentifier.removeAll()
    }
}

extension LocalNotificationCenter {
    private struct UserInfoKeys {
        static let notificationContext = "com.localnotificationcenter.userinfokeys.context"
        static let notificationIdentifier = "com.localnotificationcenter.userinfokeys.identifier"
    }
    
    private func loadScheduledLocalNotifications() {
        UNUserNotificationCenter.current()
            .getPendingNotificationRequests { [weak self] requests in
                guard let strongSelf = self else {
                    return
                }
                
                for request in requests {
                    guard let context = request.content.userInfo[UserInfoKeys.notificationContext] as? String, context == strongSelf.context else {
                        continue
                    }
                    
                    guard let identifier = request.content.userInfo[UserInfoKeys.notificationIdentifier] as? String else {
                        continue
                    }
                    
                    strongSelf.pendingNotificationRequestsByIdentifier[identifier] = request
                }
            }
    }
}
