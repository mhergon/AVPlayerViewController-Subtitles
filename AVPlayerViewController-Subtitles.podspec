Pod::Spec.new do |spec|
  spec.name             = 'AVPlayerViewController-Subtitles'
  spec.platform         = :ios, "8.0"
  spec.version          = '1.2.3'
  spec.license          = { :type => 'Apache License, Version 2.0' }
  spec.homepage         = 'https://github.com/mhergon/AVPlayerViewController-Subtitles'
  spec.authors          = { 'Marc Hervera' => 'mhergon@gmail.com' }
  spec.summary          = 'Subtitles made easy'
  spec.source           = { :git => 'https://github.com/mhergon/AVPlayerViewController-Subtitles.git', :tag => 'v1.2.3' }
  spec.source_files     = 'Subtitles.swift'
  spec.requires_arc     = true
  spec.module_name      = 'AVPlayerViewControllerSubtitles'
  spec.framework        = 'MediaPlayer'
end
