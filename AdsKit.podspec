Pod::Spec.new do |s|
  s.name             = 'AdsKit'
  s.version          = '1.0.0'
  s.summary          = 'Unified Ad Mediation SDK for iOS (AdMob & AppLovin)'
  s.description      = <<-DESC
AdsKit provides a unified facade (AdsManager) wrapping AdMob and AppLovin SDKs with single-adapter mode, main-thread guarantees, and TTL-based preloading.
                       DESC
  s.homepage         = 'https://github.com/e-hai/AdsKit-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'e-hai' => 'contact@example.com' }
  s.source           = { :git => 'https://github.com/e-hai/AdsKit-iOS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.9'

  s.default_subspecs = 'Core', 'Admob', 'Applovin'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Sources/AdsCore/**/*.swift'
    sp.frameworks   = 'UIKit', 'Foundation'
    sp.weak_frameworks = 'UserMessagingPlatform'
  end

  s.subspec 'Admob' do |sp|
    sp.source_files = 'Sources/AdsAdmob/**/*.swift'
    sp.dependency 'AdsKit/Core'
    sp.dependency 'Google-Mobile-Ads-SDK', '~> 11.0'
  end

  s.subspec 'Applovin' do |sp|
    sp.source_files = 'Sources/AdsApplovin/**/*.swift'
    sp.dependency 'AdsKit/Core'
    sp.dependency 'AppLovinSDK', '~> 13.0'
  end
end
