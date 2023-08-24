#!/bin/bash

xcodebuild -version | awk 'NR==1{x=$0}END{print x" "$NF}'
echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"

set -euxo pipefail

disable_swizzling_key='<key>test_key_to_replace1</key>'
disable_swizzling_value='<string>test_value_to_replace1</string>'
swizzling_premain_key='<key>test_key_to_replace2</key>'
swizzling_premain_value='<string>test_value_to_replace2</string>'

fixture_name='Fixture'
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

sed -i '' -e 's|DISABLE_SWIZZLING_KEY|'$disable_swizzling_key'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|DISABLE_SWIZZLING_VALUE|'$disable_swizzling_value'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|SWIZZLING_PREMAIN_KEY|'$swizzling_premain_key'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist
sed -i '' -e 's|SWIZZLING_PREMAIN_VALUE|'$swizzling_premain_value'|' $(dirname "${BASH_SOURCE[0]}")/Fixture/Info.plist

cd $(dirname "${BASH_SOURCE[0]}")

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -scheme Fixture archive -allowProvisioningUpdates -quiet

xcodebuild -destination generic/platform=iOS -archivePath Fixture.xcarchive -exportArchive -exportPath output -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates -quiet

mv ./output/Fixture.ipa ./output/$fixture_name.ipa

sed -i '' -e 's|'$disable_swizzling_key'|DISABLE_SWIZZLING_KEY|' ./Fixture/Info.plist
sed -i '' -e 's|'$disable_swizzling_value'|DISABLE_SWIZZLING_VALUE|' ./Fixture/Info.plist
sed -i '' -e 's|'$swizzling_premain_key'|SWIZZLING_PREMAIN_KEY|' ./Fixture/Info.plist
sed -i '' -e 's|'$swizzling_premain_value'|SWIZZLING_PREMAIN_VALUE|' ./Fixture/Info.plist
