#
# Be sure to run `pod lib lint XYIAPKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XYIAPKit'
  s.version          = '1.0.1'
  s.summary          = 'In App purchase sdk, support auto-renewable subscription'
  s.description      = <<-DESC
  
  非常好用的内购组件，支持自动续期订阅的过期校验、票据检验、简单易用
  提供功能：
    1）、产品查询
    2）、产品购买
    3）、恢复内购
    4）、票据校验
    5）、交易存储

                       DESC


  s.homepage         = 'https://github.com/mqc123450/XYIAPKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qichao.ma' => '“qichao.ma@quvideo.com”' }
  s.source           = { :git => 'https://github.com/mqc123450/XYIAPKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.platform = :ios, '8.0'
  s.source_files = 'XYIAPKit/*.h'
  s.public_header_files = 'XYIAPKit/*.h'
  s.frameworks = 'StoreKit'

  s.frameworks = 'StoreKit'
  s.requires_arc = true
  s.default_subspec = 'Core'


  s.subspec 'Core' do |core|
    core.source_files = 'XYIAPKit/Core/*.{h,m}'
  end
  
  s.subspec 'KeychainPersistence' do |ke|
      ke.dependency 'XYIAPKit/Core'
      ke.source_files = 'XYIAPKit/Persistence/KeychainPersistence/*.{h,m}'
      ke.frameworks = 'Security'
  end
  
  s.subspec 'UserDefaultPersistence' do |us|
      us.dependency 'XYIAPKit/Core'
      us.source_files = 'XYIAPKit/Persistence/UserDefaultPersistence/*.{h,m}'
  end

  s.subspec 'iTunesReceiptVerify' do |it|
    it.dependency 'XYIAPKit/Core'
    it.source_files = 'XYIAPKit/Receipt/iTunesReceiptVerify/*.{h,m}'
    it.dependency 'YYModel', '~> 1.0.4'
  end

end
