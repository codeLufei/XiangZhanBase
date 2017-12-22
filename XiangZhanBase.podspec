#
# Be sure to run `pod lib lint XiangZhanBase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'XiangZhanBase'
    s.version          = '0.0.1'
    s.summary          = 'XiangZhanBase is a basic class'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    TODO: Add long description of the pod here.
    DESC
    
    s.homepage         = 'https://github.com/codeLufei/XiangZhanBase'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'codeLufei' => 'cfj18238815117@163.com' }
    s.source           = { :git => 'https://github.com/codeLufei/XiangZhanBase.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '8.0'
    
    s.source_files = 'XiangZhanBase/Classes/**/*'
    
    # s.resource_bundles = {
    #   'XiangZhanBase' => ['XiangZhanBase/Assets/*.png']
    # }
    s.requires_arc = true
    s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'AFNetworking'
    s.dependency 'GTMBase64'
    s.dependency 'WebViewJavascriptBridge'
    s.dependency 'MJRefresh'
    s.dependency 'Masonry'
    s.dependency 'JSONModel'
    s.dependency 'MBProgressHUD', '~> 0.9'
end

