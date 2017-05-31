Pod::Spec.new do |s|

s.name         = "ImageLoader"
s.version      = "1.0.0"
s.summary      = "Loading images across a network"
s.homepage     = "https://github.com/Mobelux/ImageLoader"
s.license      = "MIT"

s.author             = { "Mobelux" => "contact@mobelux.com" }
s.social_media_url   = "http://twitter.com/mobelux"

s.ios.deployment_target = "10.0"

s.source       = { :git => "https://github.com/Mobelux/ImageLoader.git", :tag => "#{s.version}" }
s.source_files  = "ImageLoader", "ImageLoader/**/*.{h,m,swift}"

s.framework  = "UIKit"
end
