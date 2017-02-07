Pod::Spec.new do |s|
  s.name             = 'NRSPieChart'
  s.version          = '0.1.0'
  s.summary          = 'A PieChart control that supports slice animations, and interactions.'

  s.description      = <<-DESC
NRSPieChart is a UIView subclass that presents a customizable PieChart graph. The class will render smooth animations of PieChart slices and colors when the data model changes and the PieChart is refreshed. The data model and delegate have similar semantics to that of a UITableView or UICollectionView. NRSPieChart attributes are IBInspectable, so they can easily be configured directly in Interface Builder.
DESC

  s.homepage         = 'https://github.com/neils4fun/NRSPieChart'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'neils4fun' => 'macneil@neils4fun.com' }
  s.source           = { :git => 'https://github.com/neils4fun/NRSPieChart.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'NRSPieChart/Classes/**/*'
  
  # s.resource_bundles = {
  #   'NRSPieChart' => ['NRSPieChart/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
