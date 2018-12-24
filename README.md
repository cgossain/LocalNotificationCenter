# LocalNotificationCenter

[![CI Status](https://img.shields.io/travis/cgossain/LocalNotificationCenter.svg?style=flat)](https://travis-ci.org/cgossain/LocalNotificationCenter)
[![Version](https://img.shields.io/cocoapods/v/LocalNotificationCenter.svg?style=flat)](https://cocoapods.org/pods/LocalNotificationCenter)
[![License](https://img.shields.io/cocoapods/l/LocalNotificationCenter.svg?style=flat)](https://cocoapods.org/pods/LocalNotificationCenter)
[![Platform](https://img.shields.io/cocoapods/p/LocalNotificationCenter.svg?style=flat)](https://cocoapods.org/pods/LocalNotificationCenter)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

LocalNotificationCenter is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LocalNotificationCenter'
```

## Usage Instructions

LocalNotificationCenter is a lightweight wrapper around the UserNotifications
framework, and can be used to easily schedule and manage local notifications on
iOS.

### Notification Context
Every instance of LocalNotificationCenter maintains its own context. The default notification center uses a default context, however it's possible to create instances with separate contexts.

All actions performed in a LocalNotificationCenter instance pertain to its own context only.

```
/// Scoped to the default context.
let defaultNotificationCenter = LocalNotificationCenter.default


/// Scoped to a unique context.
let uniqueNotificationCenter = LocalNotificationCenter(context: "my_unique_context")
```


### Scheduling a Local Notification
```
// create a unique identifier for this notification (i.e. some database id)
let identifier = <Some Unique Identifier>

// repeat monthly on the 24th day, at 8:30am
let date = DateComponents()
date.day = 24
date.hour = 8
date.minutes = 30

// schedule a new one
LocalNotificationCenter.default.scheduleLocalNotification(withIdentifier: identifier,
                                                          body: message,
                                                          dateMatching: date,
                                                          repeats: true)
```

### Cancelling a Single Pending Local Notification
You can cancel a previously scheduled notification via its unique identifier.
```
LocalNotificationCenter.default.cancelScheduledLocalNotification(forIdentifier: identifier)
```

### Cancelling All Pending Local Notifications
In some cases, you might want to cancel all previously scheduled notifications within the context.
```
LocalNotificationCenter.default.cancelAllScheduledLocalNotifications()
```

## Author

cgossain, cgossain@gmail.com

## License

LocalNotificationCenter is available under the MIT license. See the LICENSE file for more info.
