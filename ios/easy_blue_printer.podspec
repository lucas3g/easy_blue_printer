#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint easy_blue_printer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'easy_blue_printer'
  s.version          = '2.0.0'
  s.summary          = 'The **Easy Blue Printer** plugin allows seamless integration of Bluetooth printers in a Flutter app, enabling the scanning, connection, and printing functionality.'
  s.description      = <<-DESC
The **Easy Blue Printer** plugin allows seamless integration of Bluetooth printers in a Flutter app, enabling the scanning, connection, and printing functionality.
                       DESC
  s.homepage         = 'https://github.com/lucas3g/easy_blue_printer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Maktub Company' => 'desenvolvimento@elinfo.com.br' }
  s.source           = { :path => '.' }
  s.source_files     = 'easy_blue_printer/Sources/easy_blue_printer/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'easy_blue_printer_privacy' => ['easy_blue_printer/Sources/easy_blue_printer/PrivacyInfo.xcprivacy']
  }
end
