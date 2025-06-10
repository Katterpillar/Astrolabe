Pod::Spec.new do |s|
  s.name = 'Astrolabe'
  s.version = '5.1.9'
  s.summary = 'Cells management library'

  s.homepage = 'https://github.com/netcosports/Astrolabe'
  s.license = { :type => "MIT" }
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com',
    'Vladimir Burdukov' => 'vladimir.burdukov@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Astrolabe.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'

  s.swift_versions = ['5.0', '5.1']

  s.default_subspec = 'Core'

  s.subspec 'Core' do |sub|
    sub.source_files = 'Sources/Core/*.swift'
    sub.tvos.exclude_files = ['Sources/Core/*PagerSource.swift', 'Sources/Core/*PagerCollectionViewCell.swift']

    sub.dependency 'RxSwift', '~> 6.8.0'
    sub.dependency 'RxCocoa', '~> 6.8.0'
  end

  s.subspec 'Loaders' do |sub|
    sub.source_files = 'Sources/Loaders/*.swift'
    sub.dependency 'Gnomon/Core', '~> 5'
    sub.dependency 'Astrolabe/Core'
  end
end
