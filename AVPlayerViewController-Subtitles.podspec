Pod::Spec.new do |spec|
  spec.name             = 'AVPlayerViewController-Subtitles'
  spec.ios.deployment_target = '8.0'
  spec.tvos.deployment_target = '9.0'
  spec.version          = "1.3.0"
  spec.license          = { :type => 'Apache License, Version 2.0' }
  spec.homepage         = 'https://github.com/mhergon/AVPlayerViewController-Subtitles'
  spec.authors          = { 'Marc Hervera' => 'mhergon@gmail.com' }
  spec.summary          = 'Subtitles made easy'
  spec.source           = { :git => 'https://github.com/mhergon/AVPlayerViewController-Subtitles.git', :tag => 'v1.3.0' }
  spec.source_files     = 'Subtitles.swift'
  spec.requires_arc     = true
  spec.module_name      = 'AVPlayerViewControllerSubtitles'
  spec.framework        = 'MediaPlayer'
  spec.swift_version	= '4.2'
end
