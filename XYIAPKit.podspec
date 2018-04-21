#
# Be sure to run `pod lib lint XYIAPKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XYIAPKit'
  s.version          = '0.0.3'
  s.summary          = 'A short description of XYIAPKit.'
  s.description      = <<-DESC
  
  好用的内购组件

                       DESC

  s.homepage         = 'git@192.168.1.33:ioscomponentgroup/XYIAPKit.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qichao.ma' => '“qichao.ma@quvideo.com”' }
  s.source           = { :git => 'http://192.168.1.33:9090/ioscomponentgroup/XYIAPKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.platform = :ios, '8.0'
  s.source_files = 'XYIAPKit/*.h'
  s.public_header_files = 'XYIAPKit/*.h'
  s.frameworks = 'StoreKit'

  s.frameworks = 'StoreKit'
  s.requires_arc = true
  s.default_subspec = 'Core'


  s.subspec 'Core' do |core|
    core.source_files = 'XYIAPKit/Core/*'
  end

  s.subspec 'Persistence' do |pe|
    pe.dependency 'XYIAPKit/Core'
    pe.source_files = 'XYIAPKit/Persistence/*'
    pe.frameworks = 'Security'
  end

  s.subspec 'Receipt' do |re|
    re.dependency 'XYIAPKit/Core'
    re.platform = :ios, '8.0'
    re.source_files = 'XYIAPKit/Receipt/*'
    re.dependency 'OpenSSL', '~> 1.0'
    s.resource_bundles = {
      'XYIAPKit' => ['XYIAPKit/Assets/*']
    }
  end

end
