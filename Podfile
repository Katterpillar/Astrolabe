source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

abstract_target 'Astrolabe' do
  pod 'Astrolabe', :path => '.'
  pod 'Gnomon'
  pod 'Gnomon/Decodable'
  pod 'RxSwift', '~> 6.6.0'
  pod 'RxCocoa', '~> 6.6.0'
  pod 'RxRelay', '~> 6.6.0'

  target 'Demo' do
    platform :ios, '13.0'
    pod 'SnapKit'
  end

  target 'DemoTV' do
    platform :tvos, '13.0'
    pod 'SnapKit'
  end

  abstract_target 'Tests' do
    pod 'Astrolabe/Loaders', :path => '.'

    pod 'Quick'
    pod 'Nimble'
    pod 'RxTest', '~> 6.6.0'
    pod 'RxBlocking', '~> 6.6.0'

    target 'iOSTests' do
      platform :ios, '13.0'
    end

    target 'tvOSTests' do
      platform :tvos, '13.0'
    end
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) TEST'
    end
  end
end
