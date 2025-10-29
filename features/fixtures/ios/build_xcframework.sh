#!/bin/bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail

disable_swizzling_key=''
disable_swizzling_value=''
swizzling_premain_key=''
swizzling_premain_value=''

fixture_name='FixtureXcFramework'
for ((i=1;i<=$#;i++));
do
    if [ ${!i} = '--fixtureName' ]
    then ((i++))
        fixture_name=${!i};
    fi
    if [ ${!i} = '--disableSwizzling' ]
    then
        disable_swizzling_key='<key>disableSwizzling</key>'
        disable_swizzling_value='<true/>\t\t\t\t\t\t\t\t\t\t';
    fi
    if [ ${!i} = '--swizzlingPremain' ]
    then
        swizzling_premain_key='<key>swizzleViewLoadPreMain</key>'
        swizzling_premain_value='<true/>\t\t\t\t\t\t\t\t\t'
    fi
done;

unzip BugsnagPerformance.xcframework.zip
unzip BugsnagPerformanceSwift.xcframework.zip
unzip BugsnagPerformanceNamedSpans.xcframework.zip

cp $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.template.plist $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist

sed -i '' -e 's|DISABLE_SWIZZLING_KEY|'$disable_swizzling_key'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|DISABLE_SWIZZLING_VALUE|'$disable_swizzling_value'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|SWIZZLING_PREMAIN_KEY|'$swizzling_premain_key'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|SWIZZLING_PREMAIN_VALUE|'$swizzling_premain_value'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -archivePath $fixture_name.xcarchive -scheme Fixture -project FixtureXcFramework.xcodeproj archive -allowProvisioningUpdates -quiet

xcodebuild -destination generic/platform=iOS -archivePath $fixture_name.xcarchive -exportArchive -exportPath output -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates -quiet

mv ./output/Fixture.ipa ./output/$fixture_name.ipa

#rm ./Fixture/Info.plist
