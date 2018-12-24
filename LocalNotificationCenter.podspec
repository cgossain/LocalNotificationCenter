Pod::Spec.new do |s|
  s.name             = 'LocalNotificationCenter'
  s.version          = '0.2.0'
  s.summary          = 'A lightweight library for scheduling local notifications on iOS, written in Swift.'
  s.description      = <<-DESC
  A lightweight library for scheduling local notifications on iOS, written in Swift.
                       DESC
  s.homepage         = 'https://github.com/cgossain/LocalNotificationCenter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cgossain' => 'cgossain@gmail.com' }
  s.source           = { :git => 'https://github.com/cgossain/LocalNotificationCenter.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.3'
  s.source_files = 'LocalNotificationCenter/Classes/**/*'
  s.framework    = 'UserNotifications'
end
