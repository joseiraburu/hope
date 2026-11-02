# Complemento de video MP4 (H.264) de HOPE para iOS, con AVFoundation.
Pod::Spec.new do |s|
  s.name             = 'hope_media'
  s.version          = '0.3.0'
  s.summary          = 'Video MP4 (H.264) para HOPE con el codificador de iOS.'
  s.description      = 'Codificacion de video MP4 (H.264) con AVFoundation para HOPE.'
  s.homepage         = 'https://github.com/joseiraburu/hope'
  s.license          = { :type => 'GPL-3.0-or-later' }
  s.author           = { 'HOPE' => 'https://github.com/joseiraburu/hope' }
  s.source           = { :path => '.' }
  s.source_files     = 'hope_media/Sources/hope_media/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.frameworks       = 'AVFoundation', 'CoreMedia', 'CoreVideo', 'Accelerate'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
