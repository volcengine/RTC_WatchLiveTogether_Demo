Pod::Spec.new do |spec|
  spec.name         = 'LiveShareDemo'
  spec.version      = '1.0.0'
  spec.summary      = 'LiveShareDemo APP'
  spec.description  = 'LiveShareDemo App Demo..'
  spec.homepage     = 'https://github.com/volcengine'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author       = { 'author' => 'volcengine rtc' }
  spec.source       = { :path => './' }
  spec.ios.deployment_target = '9.0'
  
  spec.source_files = '**/*.{h,m,c,mm,a}'
  spec.resource_bundles = {
    'LiveShareDemo' => ['Resource/*.xcassets', 'Resource/*.bundle']
  }
  spec.pod_target_xcconfig = {'CODE_SIGN_IDENTITY' => ''}
  spec.resources = ['Resource/*.{plist,lic}']
  spec.prefix_header_contents = '#import "Masonry.h"',
                                '#import "Core.h"',
                                '#import "LiveShareDemoConstants.h"'

                                
  spec.framework = 'CoreLocation'
  spec.dependency 'Core'
  spec.dependency 'YYModel'
  spec.dependency 'Masonry'
  spec.dependency 'VolcEngineRTC'
  spec.dependency 'SDWebImage'
  spec.dependency 'WatchBase'
  spec.dependency 'TTSDK/LivePull', '1.30.1.5-premium'

end
