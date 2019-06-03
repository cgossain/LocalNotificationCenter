Pod::Spec.new do |s|
  s.name            = 'LocalNotificationCenter'
  s.version         = '0.3.0'
  s.summary         = 'A lightweight library for scheduling local notifications on iOS, written in Swift.'
  s.description     = <<-DESC
  The LocalNotificationCenter was writted to enable a very simple and efficient way to manage local
  notifications on iOS. It offers a very simple interface, and the powerful concept of context based
  notification centers.
                       DESC
  s.homepage        = 'https://github.com/cgossain/LocalNotificationCenter'
  s.license         = { :type => 'MIT', :file => 'LICENSE' }
  s.author          = { 'cgossain' => 'cgossain@gmail.com' }
  s.source          = { :git => 'https://github.com/cgossain/LocalNotificationCenter.git', :tag => s.version.to_s }
  s.platform        = :ios, '10.3'
  s.swift_version   = '5.0'
  s.source_files    = 'LocalNotificationCenter/Classes/**/*'
  s.framework       = 'UserNotifications'
end
