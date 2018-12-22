//
//  MFTLocalNotificationCenter.swift
//  Pods
//
//  Created by Christian Gossain on 2016-08-26.
//
//

import Foundation

private let MFTLocalNotificationCenterNotificationKey = "MFTLocalNotificationCenterNotificationKey"

open class MFTLocalNotificationCenter: NSObject {
    
    open static let `default` = MFTLocalNotificationCenter()
    
    /// All local notifications that have been scheduled through the notification center.
    open var scheduledLocalNotificationsByKey: [String : UILocalNotification] {
        return mutableScheduledLocalNotificationsByKey
    }
    
    fileprivate var mutableScheduledLocalNotificationsByKey = [String : UILocalNotification]()
    
    override init() {
        super.init()
        loadScheduledLocalNotifications()
    }
    
    fileprivate func loadScheduledLocalNotifications() {
        if let scheduledLocalNotifications = UIApplication.shared.scheduledLocalNotifications {
            for notification in scheduledLocalNotifications {
                if let key = notification.userInfo?[MFTLocalNotificationCenterNotificationKey] as? String {
                    // this notification was scheduled by us, so let's track it
                    mutableScheduledLocalNotificationsByKey[key] = notification
                }
            }
        }
    }
    
    /// Returns true if a local notification is scheduled for the given key.
    open func isLocalNotificationScheduled(forKey key: String) -> Bool {
        return (mutableScheduledLocalNotificationsByKey[key] != nil)
    }
    
    /// Cancels the local notification associated with the given key if it is scheduled.
    open func cancelLocalNotification(forKey key: String) {
        if let notification = mutableScheduledLocalNotificationsByKey[key] {
            UIApplication.shared.cancelLocalNotification(notification)
            mutableScheduledLocalNotificationsByKey[key] = nil
        }
    }
    
    /// Cancels all scheduled local notifications.
    open func cancelAllLocalNotifications() {
        UIApplication.shared.cancelAllLocalNotifications()
        mutableScheduledLocalNotificationsByKey.removeAll()
    }
    
    /// Schedules a local notification with the given parameters.
    ///
    /// - parameter on: The fire date for the local notification. Pass nil to fire the notification immediately.
    ///
    @discardableResult
    open func scheduleNotification(_ on: Date?, forKey key: String, alertBody: String?, alertAction: String?, soundName: String?, launchImage: String?, userInfo: [String : AnyObject]?, repeatInterval: NSCalendar.Unit) -> UILocalNotification? {
        // ignore if the notification is already scheduled
        if isLocalNotificationScheduled(forKey: key) {
            return nil
        }
        
        // store the key in the notification user info and add additional user keys
        var notificationUserInfo: [String : AnyObject] = [MFTLocalNotificationCenterNotificationKey : key as AnyObject]
        if let userInfo = userInfo {
            for (key, value) in userInfo {
                notificationUserInfo[key] = value
            }
        }
        
        // create the local notification
        let localNotification = UILocalNotification()
        localNotification.userInfo              = notificationUserInfo
        localNotification.fireDate              = on
        localNotification.timeZone              = TimeZone.current
        localNotification.alertBody             = alertBody
        localNotification.alertAction           = alertAction
        localNotification.soundName             = soundName ?? UILocalNotificationDefaultSoundName
        localNotification.alertLaunchImage      = launchImage
        localNotification.repeatInterval        = repeatInterval
        
        // remember the notification
        mutableScheduledLocalNotificationsByKey[key] = localNotification
        
        // schedule the notification
        UIApplication.shared.scheduleLocalNotification(localNotification)
        
        // return the notification
        return localNotification
    }
    
}
