project_name='MastersThesisIOS'

platform :ios, '10.3'
project project_name, 'Beta-Development' => :release, 'Beta-Stage' => :release, 'Beta-Production' => :release, 'Release' => :release, 'Development' => :debug

inhibit_all_warnings!
use_frameworks!

workspace project_name + '.xcworkspace'

target project_name do
    project project_name + '.xcodeproj'
    pod 'SwiftLint', '~> 0.27'
    
    pod 'SwiftGen', '~> 6.3'
    pod 'LicensePlist', '~> 3.0.5'
    pod 'Tangram-es', '~> 0.15.0'
    pod 'RealmSwift', '~> 10.7.2'
    
    pod 'Firebase/Crashlytics', '~> 7.11.0'
    pod 'Firebase/Analytics', '~> 7.11.0'
    
    target 'MastersThesisIOSTests' do
        inherit! :complete
    end
end

target 'Localization' do
    project 'Localization/Localization.xcodeproj'
    pod 'ACKLocalization', '~> 1.1'
end
